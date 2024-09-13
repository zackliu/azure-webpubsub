extension microsoftGraph
// Find document https://learn.microsoft.com/en-us/graph/templates/reference/serviceprincipals?view=graph-bicep-1.0

param identityName string
param federatedIdentityObjectId string

resource resourceApp 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: identityName
  displayName: 'Resource Application for socket.io serverless sample'
  web: {
    implicitGrantSettings: {
      enableAccessTokenIssuance: true
      enableIdTokenIssuance: true
    }
  }

  // resource fed 'federatedIdentityCredentials@v1.0' = {
  //   audiences: [
  //     'api://AzureADTokenExchange'
  //   ]
  //   description: 'Federated Identity'
  //   issuer: 'https://login.microsoftonline.com/${subscription().tenantId}/v2.0'
  //   name: '${identityName}-federatedIdentity'
  //   subject: federatedIdentityObjectId
  // }
}

// resource servicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
//   appId: resourceApp.appId
// }

output applicationClientId string = resourceApp.appId

