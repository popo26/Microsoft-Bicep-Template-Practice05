param cosmosDBAccountName string = 'toyrnd-${uniqueString(resourceGroup().id)}'
param cosmosDBDatabaseThroughput int = 400
param location string = resourceGroup().location
param storageAccountName string

var cosmosDBDatabaseName = 'FlightTests'
var cosmosDBContainerName = 'FlightTests'
var cosmosDBContainerPartitionKey = '/droneId'
var logAnalyticsWorkspaceName = 'ToyLogs'
var cosmosDBAccountDiagnosticsSettingsName = 'route-logs-to-log-analytics'
var storageAccountBlobDiagnosticSettingName = 'route-logs-to-log-analytics'

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2020-04-01' = {
  name: cosmosDBAccountName
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource cosmosDBDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2020-04-01' = {
  parent: cosmosDBAccount
  name: cosmosDBDatabaseName
  properties: {
    resource: {
      id: cosmosDBDatabaseName
    }
    options: {
      throughput: cosmosDBDatabaseThroughput
    }
  }

  resource container 'containers' = {
    name: cosmosDBContainerName
    properties: {
      resource: {
        id: cosmosDBContainerName
        partitionKey: {
          kind: 'Hash'
          paths: [
            cosmosDBContainerPartitionKey
          ]
        }
      }
      options: {}
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource cosmosDBAcountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: cosmosDBAccount
  name: cosmosDBAccountDiagnosticsSettingsName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category:'DataPlaneRequests'
        enabled:true
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName

  resource blogService 'blobServices' existing = {
    name:'default'
  }
}

resource storageAccountBlobDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: storageAccount::blogService
  name: storageAccountBlobDiagnosticSettingName
  properties: {
    workspaceId:logAnalyticsWorkspace.id
    logs:[
      {
        category:'StorageRead'
        enabled:true
      }
      {
        category:'StorageWrite'
        enabled:true
      }
      {
        category:'StorageDelete'
        enabled:true
      }
    ]
  }
}
