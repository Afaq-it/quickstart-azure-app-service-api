from flask import Flask, request, jsonify
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential
from msal import ConfidentialClientApplication
import jwt
import os

app = Flask(__name__)

# Azure AD App Configurations
TENANT_ID = "your_tenant_id"
CLIENT_ID = "your_client_id"
CLIENT_SECRET = "your_client_secret"
authority = f"https://login.microsoftonline.com/{TENANT_ID}"
app_client = ConfidentialClientApplication(CLIENT_ID, authority=authority, client_credential=CLIENT_SECRET)

# Managed Identity and Blob Storage Setup
credential = DefaultAzureCredential()
STORAGE_ACCOUNT_NAME = "your_storage_account_name"
CONTAINER_NAME = "file-uploads"

blob_service_client = BlobServiceClient(
    f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net",
    credential=credential
)
container_client = blob_service_client.get_container_client(CONTAINER_NAME)
if not container_client.exists():
    container_client.create_container()

def validate_token(token):
    try:
        # Decode the token without verifying signature to get claims (optional)
        decoded_token = jwt.decode(token, options={"verify_signature": False}, algorithms=["RS256"])
        # Typically, check the issuer and audience claims to validate the token:
        # issuer should match the authority URL, audience should match the client ID
        if decoded_token["aud"] != CLIENT_ID:
            raise jwt.InvalidTokenError("Invalid audience")
        if decoded_token["iss"] != f"https://login.microsoftonline.com/{TENANT_ID}/v2.0":
            raise jwt.InvalidTokenError("Invalid issuer")
        return True
    except jwt.ExpiredSignatureError:
        return False
    except jwt.InvalidTokenError:
        return False

@app.route("/upload", methods=["POST"])
def upload_file():
    # Validate the token in the Authorization header
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({"error": "Unauthorized"}), 401

    token = auth_header[len("Bearer "):]
    if not validate_token(token):
        return jsonify({"error": "Invalid or expired token"}), 401

    # Handle File Upload
    if "file" not in request.files:
        return jsonify({"error": "No file part in the request"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    try:
        blob_client = container_client.get_blob_client(file.filename)
        blob_client.upload_blob(file, overwrite=True)
        return jsonify({"message": f"File '{file.filename}' uploaded successfully!"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
