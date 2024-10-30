targetScope = 'subscription'

@description('The Azure region where the resources should be deployed')
param deploymentLocation string = 'switzerlandnorth'

@description('The base name of the web application')
param webAppNameBase string = 'sampleapi-prod'

@description('The name of the Azure Container Registry')
param registryName string = 'latzox'

@description('Deploy the Azure Container Registry')
param deployAcr bool = true

@description('Deploy the role assignment for the web application')
param deployRoleAssignment bool = true

@description('Deploy the web application')
param deployApi bool = true

@description('Role definition ID for ACR pull role')
param roleDefinitionId string = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

@description('The subscription ID for the shared services subscription')
param subIdSharedServices string = '00000000-0000-0000-0000-000000000000'

@description('Subscription ID for the File Transfer application')
param subIdSampleApi string = '00000000-0000-0000-0000-000000000000'

@description('The SKU for the App Service Plan.')
param aspSkuName string = 'B1'

@description('The Docker image to deploy to the web application')
param dockerImage string = 'latzox.azurecr.io/sample-azure-app-service-api:latest'

@description('New Identity resource group.')
param identityResourceGroup string = 'rg-identitysampleapi-prod-001'

@description('API resource group.')
param apiResourceGroup string = 'rg-sampleapiapp-prod-001'

@description('Existing Azure Container Registry resource group.')
param acrResourceGroup string = 'rg-acr-prod-001'

@description('The resource group for the managed identity')
resource identityRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: identityResourceGroup
  location: deploymentLocation
}

@description('The resource group for the web application')
resource apiRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
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
  scope: resourceGroup(subIdSampleApi, identityResourceGroup)
  params: {
    roleDefinitionId: roleDefinitionId
    webAppNameBase: webAppNameBase
  }
  dependsOn: [
    identityRg
    acr
  ]
}

@description('Deploy the web application')
module app 'app/app.bicep' = if (deployApi) {
  name: 'app-deployment'
  scope: resourceGroup(subIdSampleApi, apiResourceGroup)
  params: {
    aspSkuName: aspSkuName
    dockerImage: dockerImage
    webAppNameBase: webAppNameBase
    managedIdentityId: roleAssingment.outputs.managedIdentityId
  }
  dependsOn: [
    apiRg
  ]
}
