@description('Role definition ID for ACR pull role')
param roleDefinitionId string

@description('The base name for the web application')
param webAppNameBase string

@description('The tags to apply to the resources')
param tags object = {
  workload: 'Sample API'
  topic: 'Identity'
  environment: 'Production'
}

@description('User-assigned managed identity for accessing the container registry')
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: '${webAppNameBase}-identity'
  location: resourceGroup().location
  tags: tags
}

@description('Role assignment for managed identity to pull images from ACR')
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentity.id, resourceGroup().id, roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: managedIdentity.properties.principalId
  }
}

output managedIdentityId string = managedIdentity.id
output managedIdentityClientId string = managedIdentity.properties.clientId
