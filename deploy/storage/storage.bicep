@description('Storage account name.')
param storageAccountName string

@description('Storage account SKU.')
param storageAccountSku string

@description('Storage account kind.')
param storageAccountKind string

@description('Container name.')
param containerName string

@description('Storage account deployment.')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
}

@description('Blob service deployment.')
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storageAccount
}

@description('Container deployment.')
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: containerName
  parent: blobService
}
