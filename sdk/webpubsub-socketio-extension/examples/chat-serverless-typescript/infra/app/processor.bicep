param name string
param location string = resourceGroup().location
param tags object = {}
param applicationInsightsName string = ''
param appServicePlanId string
param appSettings object = {}
param runtimeName string 
param runtimeVersion string 
param serviceName string = 'processor'
param storageAccountName string
param instanceMemoryMB int = 2048
param maximumInstanceCount int = 100
param identityId string = ''
param identityClientId string = ''
param socketIOEndpoint string
param authApplicationCilentId string

var applicationInsightsIdentity = 'ClientId=${identityClientId};Authorization=AAD'

module processor '../core/host/functions-flexconsumption.bicep' = {
  name: '${serviceName}-functions-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    identityType: 'UserAssigned'
    identityId: identityId
    identityClientId: identityClientId
    appSettings: union(appSettings,
      {
        AzureWebJobsStorage__clientId : identityClientId
        APPLICATIONINSIGHTS_AUTHENTICATION_STRING: applicationInsightsIdentity
        WebPubSubForSocketIOConnectionString__endpoint: socketIOEndpoint
        WebPubSubForSocketIOConnectionString__clientId: identityClientId
        WebPubSubForSocketIOConnectionString__credential: 'managedidentity'
      })
    applicationInsightsName: applicationInsightsName
    appServicePlanId: appServicePlanId
    runtimeName: runtimeName
    runtimeVersion: runtimeVersion
    storageAccountName: storageAccountName
    instanceMemoryMB: instanceMemoryMB 
    maximumInstanceCount: maximumInstanceCount
    authApplicationClientId: authApplicationCilentId
  }
}

output SERVICE_PROCESSOR_NAME string = processor.outputs.name
output SERVICE_API_IDENTITY_PRINCIPAL_ID string = processor.outputs.identityPrincipalId
