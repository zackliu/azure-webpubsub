
# Socket.IO Chat in Serverless Mode (C#)

This project is an Azure Function-based group chat application that leverages WebPubSub for Socket.IO to enable real-time communication between clients.

## Setup

### Update Connection String

```bash
func settings add WebPubSubForSocketIOConnectionString "<connection string>"
```

## Run the sample locally

### Run the Azure Storage Emulator

```bash
azurite
```

If you haven't installed azurite, you can install it by running:

```bash
npm install -g azurite
```

Check more detail in [https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite]

### Set the event handler in Socket.IO Service and use Tunnel Tool to forward the request to local

Install tunnel tool if you haven't installed it:

```bash
npm install -g @azure/web-pubsub-tunnel-tool
```

Start the tunnel tool:

```bash
awps-tunnel run --hub hub --connection "<connection string>" --upstream http://127.0.0.1:7071
```

Update the Socket.IO Service event handler to use tunnel to forward requests.

```bash
az webpubsub hub create -n <resource name> -g <resource group> --hub-name hub --event-handler url-template="tunnel:///runtime/webhooks/socketio" user-event-pattern="*"
```

### Start the Azure Function

```bash
func start
```

You may see the following output:

```text
index:  http://localhost:7071/api/index

Negotiate: [GET] http://localhost:7071/api/Negotiate

TriggerBindingForChat: socketIOTrigger

TriggerBindingForConnect: socketIOTrigger

TriggerBindingForConnected: socketIOTrigger

TriggerBindingForDisconnected: socketIOTrigger
```

Visit the url pointing to `index` function to see the chat application.
