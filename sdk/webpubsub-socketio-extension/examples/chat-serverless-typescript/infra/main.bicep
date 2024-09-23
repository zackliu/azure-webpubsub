targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
@allowed(['australiaeast', 'eastasia', 'eastus', 'eastus2', 'northeurope', 'southcentralus', 'southeastasia', 'swedencentral', 'uksouth', 'westus2', 'eastus2euap'])
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

param processorServiceName string = ''
param processorUserAssignedIdentityName string = ''
param applicationInsightsName string = ''
param appServicePlanName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''
param storageAccountName string = ''
param disableLocalAuth bool = true

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var functionName = !empty(processorServiceName) ? processorServiceName : '${abbrs.webSitesFunctions}processor-${resourceToken}'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// User assigned managed identity to be used by the Function App to reach storage and service bus
module processorUserAssignedIdentity './core/identity/userAssignedIdentity.bicep' = {
  name: 'processorUserAssignedIdentity'
  scope: rg
  params: {
    location: location
    tags: tags
    identityName: !empty(processorUserAssignedIdentityName) ? processorUserAssignedIdentityName : '${abbrs.managedIdentityUserAssignedIdentities}processor-${resourceToken}'
  }
}

// Create an application used in Azure Function authenication and it uses the previously created managed identity as federated identity
module federatedApplication './core/identity/federatedIdentity.bicep' = {
  name: 'federatedApplication'
  scope: rg
  params: {
    identityName: '${abbrs.servicePrincipal}api-${resourceToken}'
    federatedIdentityObjectId: processorUserAssignedIdentity.outputs.identityPrincipalId
    redirectUri: 'https://${functionName}.azurewebsites.net/.auth/login/aad/callback'
  }
}

module socketio './app/socketio.bicep' = {
  name: 'socketio'
  scope: rg
  params: {
    name:'${abbrs.socketio}${resourceToken}'
    location: location
    identityId: processorUserAssignedIdentity.outputs.identityId
  }
}

// The application backend
module processor './app/processor.bicep' = {
  name: 'processor'
  scope: rg
  params: {
    name: functionName
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'node'
    runtimeVersion: '20'
    storageAccountName: storage.outputs.name
    identityId: processorUserAssignedIdentity.outputs.identityId
    identityClientId: processorUserAssignedIdentity.outputs.identityClientId
    authApplicationCilentId: federatedApplication.outputs.applicationClientId
    socketIOEndpoint: 'https://${socketio.outputs.uri}'
    appSettings: {
    }
  }
}

// Backing storage for Azure functions processor
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
    containers: [{name: 'deploymentpackage'}]
    publicNetworkAccess: 'Enabled'
  }
}

var storageRoleDefinitionId  = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' //Storage Blob Data Owner role

// Allow access from processor to storage account using a managed identity
module storageRoleAssignmentApi 'app/storage-Access.bicep' = {
  name: 'storageRoleAssignmentPRocessor'
  scope: rg
  params: {
    storageAccountName: storage.outputs.name
    roleDefinitionID: storageRoleDefinitionId
    principalID: processorUserAssignedIdentity.outputs.identityPrincipalId
  }
}

module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'FC1'
      tier: 'FlexConsumption'
    }
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    disableLocalAuth: disableLocalAuth
  }
}

var monitoringRoleDefinitionId = '3913510d-42f4-4e42-8a64-420c390055eb' // Monitoring Metrics Publisher role ID

// Allow access from processor to application insights using a managed identity
module appInsightsRoleAssignmentApi './core/monitor/appinsights-access.bicep' = {
  name: 'appInsightsRoleAssignmentPRocessor'
  scope: rg
  params: {
    appInsightsName: monitoring.outputs.applicationInsightsName
    roleDefinitionID: monitoringRoleDefinitionId
    principalID: processorUserAssignedIdentity.outputs.identityPrincipalId
  }
}

var WebPubSubServiceOwnerDefinitionId = '12cf5a90-567b-43ae-8102-96cf46c7d9b4' // Web PubSub Service Owner role ID

// Allow access from processor to socketio using a managed identity
module socketioRoleAssignmentApi './core/identity/assignRole.bicep' = {
  name: 'socketio-owner'
  scope: rg
  params: {
    principalId: processorUserAssignedIdentity.outputs.identityPrincipalId
    roleDefinitionId: WebPubSubServiceOwnerDefinitionId
    principalType: 'ServicePrincipal'
  }
}

// module hub './app/socketiohub.bicep' = {
//   scope: rg
//   name: 'hubSettings'
//   params: {
//     name: socketio.name
//     hubName: 'hub'
//     urlTemplate: 'https://${functionName}.azurewebsites.net/runtime/webhooks/socketio?code=${processor.outputs.masterKey}'
//     audience: federatedApplication.outputs.applicationClientId
//   }
// }

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output SERVICE_PROCESSOR_NAME string = processor.outputs.SERVICE_PROCESSOR_NAME
output AZURE_FUNCTION_NAME string = processor.outputs.SERVICE_PROCESSOR_NAME
output RESOURCE_GROUP_NAME string = rg.name
output SOCKETIO_NAME string = socketio.outputs.name
output SP_ID string = federatedApplication.outputs.applicationClientId
