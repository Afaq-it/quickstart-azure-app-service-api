targetScope = 'subscription'

@description('The Azure region where the resources should be deployed')
param deploymentLocation string = 'switzerlandnorth'

@description('The base name of the web application')
param webAppNameBase string = 'filetransfer-prod'

@description('The name of the Azure Container Registry')
param registryName string = 'latzox'

@description('Deploy the Azure Container Registry')
param deployAcr bool = true

@description('Deploy the role assignment for the web application')
param deployRoleAssignment bool = true

@description('Deploy the web application')
param deployApi bool = true

@description('Deploy the storage account')
param deployStorage bool = true

@description('Role definition ID for ACR pull role')
param roleDefinitionId string = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

@description('The subscription ID for the shared services subscription')
param subIdSharedServices string = 'c2678acf-6c55-482b-9021-8d2021597bb9'

@description('Subscription ID for the File Transfer application')
param subIdFileTransfer string = '00000000-0000-0000-0000-000000000000'

@description('The SKU for the App Service Plan.')
param aspSkuName string = 'F1'

@description('The Docker image to deploy to the web application')
param dockerImage string = 'latzox.azurecr.io/file-transfer:1.0.0'

@description('New Storage account resource group.')
param storageAccountResourceGroup string = 'rg-filetransferstorage-prod-001'

@description('New Identity resource group.')
param identityResourceGroup string = 'rg-filetransferidentity-prod-001'

@description('API resource group.')
param apiResourceGroup string = 'rg-filetransferapi-prod-001'

@description('Existing Azure Container Registry resource group.')
param acrResourceGroup string = 'rg-acr-prod-001'

@description('Storage account name.')
param storageAccountName string = 'safiletransferprod001'

@description('Storage account SKU.')
param storageAccountSku string = 'Standard_LRS'

@description('Storage account kind.')
param storageAccountKind string = 'StorageV2'

@description('Container name.')
param containerName string = 'filedrop'

resource StorageSA 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: storageAccountResourceGroup
  location: deploymentLocation
}

resource IdentitySA 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: identityResourceGroup
  location: deploymentLocation
}

resource APISA 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: apiResourceGroup
  location: deploymentLocation
}

@description('The user-assigned managed identity for the web application')
module acr 'acr/acr.bicep' = if (deployAcr) {
  name: 'acr-deployment'
  scope: resourceGroup(subIdSharedServices, acrResourceGroup)
  params: {
    location: deploymentLocation
    registryName: registryName
    sku: 'Standard'
  }
}

@description('Deploy the role assignment for the web application')
module roleAssingment 'roleassignment/role.bicep' = if (deployRoleAssignment) {
  name: 'roleassignment-deployment'
  scope: resourceGroup(subIdFileTransfer, identityResourceGroup)
  params: {
    roleDefinitionId: roleDefinitionId
    webAppNameBase: webAppNameBase
  }
}

module storage 'storage/storage.bicep' = if (deployStorage) {
  scope: resourceGroup(subIdFileTransfer, storageAccountResourceGroup)
  name: 'storage-deployment'
  params: {
    storageAccountName: storageAccountName
    storageAccountSku: storageAccountSku
    storageAccountKind: storageAccountKind
    containerName: containerName
  }
}

@description('Deploy the web application')
module app 'api/api.bicep' = if (deployApi) {
  name: 'app-deployment'
  scope: resourceGroup(subIdFileTransfer, apiResourceGroup)
  params: {
    aspSkuName: aspSkuName
    dockerImage: dockerImage
    webAppNameBase: webAppNameBase
    managedIdentityId: roleAssingment.outputs.managedIdentityId
  }
}
