from flask import Flask, jsonify, abort
import json

app = Flask(__name__)

with open('regions.json') as f:
    azure_regions = json.load(f)

@app.route('/<region>', methods=['GET'])
def get_region_info(region):
    region = region.lower()
    
    if region in azure_regions:
        return jsonify(azure_regions[region])
    else:
        abort(404, description="Region not found")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)