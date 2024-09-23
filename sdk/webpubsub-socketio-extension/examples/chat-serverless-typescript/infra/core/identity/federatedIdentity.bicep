extension microsoftGraph
// Find document https://learn.microsoft.com/en-us/graph/templates/reference/serviceprincipals?view=graph-bicep-1.0
// Find example: https://github.com/microsoftgraph/msgraph-bicep-types/blob/main/quickstart-templates/create-fic-for-github-actions/main.bicep
// missing the callback

param identityName string
param federatedIdentityObjectId string
param redirectUri string = ''

resource resourceApp 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: identityName
  displayName: 'Resource Application for socket.io serverless sample'
  web: {
    implicitGrantSettings: {
      enableAccessTokenIssuance: true
      enableIdTokenIssuance: true
    }
    redirectUris: empty(redirectUri) ? null : [
      redirectUri
    ]
  }

  resource fed 'federatedIdentityCredentials@v1.0' = {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    description: 'Federated Identity'
    issuer: 'https://login.microsoftonline.com/${subscription().tenantId}/v2.0'
    name: '${resourceApp.uniqueName}/federatedIdentity'
    subject: federatedIdentityObjectId
  }
}

resource servicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: resourceApp.appId  
}

output applicationClientId string = resourceApp.appId
