Write-Host "Loading azd .env file from current environment"
foreach ($line in (& azd env get-values)) {
    if ($line -match "([^=]+)=(.*)") {
        $key = $matches[1]
        $value = $matches[2] -replace '^"|"$'
        [Environment]::SetEnvironmentVariable($key, $value)
    }
}

Write-Host "Finish Loading azd .env file from current environment"

# Get the function app system key for the socket.io extension
$code = (az functionapp keys list --resource-group $env:RESOURCE_GROUP_NAME --name $env:AZURE_FUNCTION_NAME --query "systemKeys.socketio_extension" --output tsv)
# Create a WebPubSub hub with an event handler pointing to the Azure Function
az webpubsub hub create `
    --name $env:SOCKETIO_NAME `
    --resource-group $env:RESOURCE_GROUP_NAME `
    --hub-name "hub" `
    --event-handler url-template="https://${env:AZURE_FUNCTION_NAME}.azurewebsites.net/runtime/webhooks/socketio?code=$code" user-event-pattern="*" auth-type="ManagedIdentity" auth-resource="$env:SP_ID"