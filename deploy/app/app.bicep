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
  }
}

@description('Deploy a web application for each region specified')
resource webApps 'Microsoft.Web/sites@2023-12-01' =  {
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
      acrUserManagedIdentityID: managedIdentityId
      linuxFxVersion: 'DOCKER|${dockerImage}'
      appSettings: [
      ]
    }
    serverFarmId: appServicePlans.id
  }
}
