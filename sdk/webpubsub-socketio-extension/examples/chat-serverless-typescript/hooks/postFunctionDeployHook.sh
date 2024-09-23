echo "Loading azd .env file from current environment..."

while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

CODE=$(az functionapp keys list -g $RESOURCE_GROUP_NAME -n $AZURE_FUNCTION_NAME --query systemKeys.socketio_extension -o tsv)
az webpubsub hub create -n $SOCKETIO_NAME -g $RESOURCE_GROUP_NAME --hub-name "hub" --event-handler url-templ
ate="https://${AZURE_FUNCTION_NAME}.azurewebsites.net/runtime/webhooks/socketio?code=${CODE}" user-event-pattern="*" auth-type="ManagedIdentity" auth-resource="$SP_ID"