import json
import sys
from azure.messaging.webpubsubservice_flask import EventHandler, make_connect_response
from azure.messaging.webpubsubservice_flask.cloud_events_protocols import ConnectionContext
from flask import Flask, request, send_from_directory, Request, Response, make_response
from azure.messaging.webpubsubservice import (
    build_authentication_token,
    WebPubSubServiceClient
)
from azure.messaging.webpubsubservice.rest import *

hub_name = 'chat'

app = Flask(__name__)
eh = EventHandler(app)

@app.route('/<path:filename>')
def index(filename):
    return send_from_directory('public', filename)

@app.route('/eventhandler/<path:event>', methods = ['Post', 'OPTIONS'])
@eh.handle_abuse_protection_validation('*')
@eh.handle_event
def process(event, connection_context: ConnectionContext = None):
    if connection_context:
        if connection_context.type == 'azure.webpubsub.sys.connect':
            return make_connect_response()
        elif connection_context.type == 'azure.webpubsub.sys.connected':
            return connection_context.user_id + ' connected', 200
        elif connection_context.type == 'azure.webpubsub.sys.disconnected':
            return '', 200
        elif connection_context.type.startswith('azure.webpubsub.user.'):
            client = WebPubSubServiceClient.from_connection_string(sys.argv[1])
            client.send_request(build_send_to_all_request(hub_name, json={
            'from': connection_context.user_id,
            'message': request.data.decode('UTF-8')
            }))
            return '', 200
        else:
            return 'Not found', 404

    # user_id = request.headers.get('ce-userid')
    # if request.headers.get('ce-type') == 'azure.webpubsub.sys.connected':
    #     return user_id + ' connected', 200
    # elif request.headers.get('ce-type') == 'azure.webpubsub.user.message':
    #     client = WebPubSubServiceClient.from_connection_string(sys.argv[1])
    #     client.send_request(build_send_to_all_request(hub_name, json={
    #         'from': user_id,
    #         'message': request.data.decode('UTF-8')
    #     }))
    #     res = Response(content_type='text/plain', status=200)
    #     return res
    # else:
    #     return 'Not found', 404


# @app.route('/eventhandler/connect', methods=['POST'])
# @eh.handle_connect
# def connect(webpubsub_request):
#     return make_connect_response()

# @app.route('/eventhandler/connected', methods=['POST'])
# @eh.handle_connected
# def connected(webpubsub_request):
#     res = make_response()
#     res.status_code = 200
#     return res

# @app.route('/eventhandler/disconnected', methods=['POST'])
# @eh.handle_disconnected
# def disconnected(webpubsub_request):
#     res = make_response()
#     res.status_code = 200
#     return res

@app.route('/negotiate')
def negotiate():
    id = request.args.get('id')
    if not id:
        return 'missing user id', 400
    
    token = build_authentication_token(sys.argv[1], hub_name, user=id)
    return {
        'url': token['url']
    }, 200

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Usage: python server.py <connection-string>')
        exit(1)
    app.run(port=8080)
