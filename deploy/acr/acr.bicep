@description('Name of the Azure Container Registry')
param registryName string

@description('The SKU of the Azure Container Registry (Basic, Standard, Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Standard'

@description('Enable admin user (recommended to be set to false in production)')
param enableAdminUser bool = false

@description('The location for the Azure Container Registry')
param location string

@description('The tags to apply to the resources')
param tags object = {
  workload: 'Shared Container Registry'
  topic: 'Registry'
  environment: 'Production'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: registryName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: enableAdminUser
  }
}

output registryLoginServer string = containerRegistry.properties.loginServer
output registryId string = containerRegistry.id
