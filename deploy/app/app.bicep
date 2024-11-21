@description('The region in which to deploy the resources')
param location string = resourceGroup().location

@description('The base name of the web application')
param webAppNameBase string

@description('The SKU for the App Service Plan.')
param aspSkuName string

@description('The Docker image to deploy to the api')
param dockerImage string

@description('The user-assigned managed identity for the api')
param managedIdentityId string

@description('The client ID of the user-assigned managed identity for the api')
param managedIdentityClientId string

@description('The tags to apply to the resources')
param tags object = {
  workload: 'File Transfer'
  topic: 'API'
  environment: 'Production'
}

@description('Deploy an app service plan for each region specified')
resource appServicePlans 'Microsoft.Web/serverfarms@2023-12-01' =  {
  name: 'asp-${webAppNameBase}'
  location: location
  tags: tags
  kind: 'linux'
  properties: {
    reserved: true
  }	
  sku: {
    name: aspSkuName
    capacity: 1
  }
}

@description('Deploy a web application for each region specified')
resource webApp 'Microsoft.Web/sites@2023-12-01' =  {
  name: 'app-${webAppNameBase}'
  location: location
  kind: 'app,linux,container'
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    siteConfig: {
      minTlsVersion: '1.3'
      http20Enabled: true
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentityClientId
      linuxFxVersion: 'DOCKER|${dockerImage}'
      appSettings: [
      ]
    }
    httpsOnly: true
    clientAffinityEnabled: false
    serverFarmId: appServicePlans.id
  }
}

resource acr 'Microsoft.Web/sites/sitecontainers@2023-12-01' = {
  name: 'deploy-container'
  parent: webApp
  properties: {
    image: dockerImage
    isMain: true
    authType: 'UserAssigned'
    userManagedIdentityClientId: managedIdentityClientId
  }
}
