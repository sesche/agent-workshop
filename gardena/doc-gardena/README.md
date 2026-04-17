# GARDENA smart system API v 2.0

* [Overview](#overview)
* [Monitoring](#monitoring-your-devices)
* [Controlling](#controlling-your-devices)
* [Document types](#document-types)
* [Rate Limits](#rate-limits)
* [Realtime API](#realtime-api)
  * [Rules of events processing](#rules-of-events-processing)
  * [Used document types](#used-document-types)
  * [Sample websocket client](#sample-websocket-client)

## Overview

With this API we aim to enable developers to *monitor* and *control* GARDENA smart system products.

Before using this API, make sure to have read through the [Getting Started](/docs/get-started) and
[API Docs](/docs/api).

## Authentication

All requests (with exception to the health check) need to be issued using a valid token obtained from the Authentication API and providing a valid API key obtained from the Developer Portal.

```bash
curl -X GET \
  https://api.smart.gardena.dev/v1/locations \
  -H 'Authorization: Bearer <ACCESS TOKEN OBTAINED FROM AUTHENTICATION API>' \
  -H 'X-Api-Key: <APP KEY OBTAINED FROM DEVELOPER PORTAL>'
```

## Monitoring your devices

As a first step you need to get hold of your `locationId` by calling `GET /locations`. This will list all locations your 
account has access to. A location gets created within an account when a smart Gateway is set up in the GARDENA app.
Currently the app restricts an account to have access to a single location only.

```bash
curl -X GET \
  https://api.smart.gardena.dev/v1/locations \
  -H 'Authorization: Bearer <ACCESS TOKEN>' \
  -H 'X-Api-Key: <APP KEY>'
```

Now you have two options to monitor your devices:

* Snapshot: You can get a point-in-time state of your devices using `GET /locations/<LOCATION ID>`. As the API is rate limited, this
  option is not suitable to get updates frequently. _Do not use frequent polling to monitor state!_ Also see the [Rate Limits](#rate-limits) section for more information.
  
```bash
curl -X GET \
  https://api.smart.gardena.dev/v1/locations/<LOCATION ID> \
  -H 'Authorization: Bearer <ACCESS TOKEN>' \
  -H 'X-Api-Key: <APP KEY>'
```
  
* Websocket: create a websocket using `POST /websocket`. This provides the websocket URL that you can open to get
  the initial state of the devices followed by any state changes that occur in realtime. For a deep dive see
  [Realtime API](#realtime-api).
  
```bash
curl -X POST \
  https://api.smart.gardena.dev/v1/websocket \
  -H 'Authorization: Bearer <ACCESS TOKEN>' \
  -H 'X-Api-Key: <APP KEY>' \
  -H 'Content-Type: application/vnd.api+json' \
  -d '{
    "data": {
      "id": "request-1",
      "type": "WEBSOCKET",
      "attributes": {
        "locationId": "<LOCATION ID>"
      }
    }
  }'
```

## Controlling your devices

Commands can be sent to devices using `PUT /command/<SERVICE ID>`. Note that this request will succeed as soon as the
command was accepted by the smart Gateway. A successful execution of the command on the device itself can be observed
by a respective state change. Example: sending command `START_SECONDS_TO_OVERRIDE` to the `VALVE` service of a smart
Water Control will result in the `activity` attribute of the service to be changed to `MANUAL_WATERING` after the device
processed the command.

Note: `id` of the command is only used for logging purposes. Also note that the `service_id` is not
the same as the `device_id`. The `service_id` values are reported in the CommonServiceDataItem objects as part of the LocationResponse:

```json
{
    "data": {...},
    "included": [
        {
            "id": <device_id>,
            "type": "DEVICE",
            "relationships": {
                "location": {...},
                "services": {
                    "data": [
                        {
                            "id": "35c85add-88e1-4681-a34c-341f913c1346:cbtg",
                            "type": "MOWER"
                        },
                        {
                            "id": "35c85add-88e1-4681-a34c-341f913c1346",
                            "type": "COMMON"
                        }
                    ]
                }
            }
        },
```

Note that the `service_id` values might include suffixes. These form part of the id and cannot be omitted.

Example of a request:

```bash
curl -X PUT \
  https://api.smart.gardena.dev/v1/command/<SERVICE ID> \
  -H 'Authorization: Bearer <ACCESS TOKEN>' \
  -H 'X-Api-Key: <APP KEY>' \
  -H 'Content-Type: application/vnd.api+json' \
  -d '{
    "data": {
  		"type": "VALVE_CONTROL", 
  		"id": "request-4", 
  		"attributes": {
          "command": "START_SECONDS_TO_OVERRIDE",
          "seconds": 60
        }
     }
  }'
```

## Document types

The API follows the [{JSON:API}](https://jsonapi.org/) standard. There are the following document types in use:

* `LOCATION`: contains the location name and the list of devices belonging to this location.
* `DEVICE`: contains a list of services that a device offers.
* Services: each service carries a set of fields describing the service state. Fields might be timestamped.
    * `COMMON`: general device information. Exists exactly once for every device.
    * `MOWER`: available on all smart SILENO mowers. Gives detailled information about mower activity and status.
    * `POWER_SOCKET`: available on the smart Power. Tells if device is operational and if power is switched on or not.
    * `SENSOR`: available on the smart Sensor. Contains latest temperature, light and soil moisture readings.
    * `VALVE`: available once on smart Water Control and smart Pressure Pump, six times on the smart Irrigation
       Control. Informs about the state of watering.
    * `VALVE_SET`: available on the smart Irrigation Control. Informs if the device is operational or not.
* Control: used to define commands to be executed on device.
    * `MOWER_CONTROL`: use to start mowing or park the mower.
    * `POWER_SOCKET_CONTROL`: use to switch on or off power.
    * `VALVE_CONTROL`: use to control watering of single valve.
    * `VALVE_SET_CONTROL`: use to switch off all watering.
* `WEBSOCKET`: contains a link to the websocket endpoint that is pre-authenticated and is valid only for a few seconds.

## Rate Limits

Rate limits are in place to prevent malicious use of the API that would impact other users.

Applications share a pool of keys that each are assigned certain quota.
An application that behaves as a good citizen of the Gardena eco system should not exceed the following limits:

* On average one call every fifteen minutes.
* 700 requests per week.
* 10 requests per 10-second interval.

These are hard limits for every application. If an application exceeds the 700 requests per week or 10 requests within the 10-second timeframe, subsequent requests will be blocked with a 429 "Too Many Requests" response status code.

These limits should not pose a problem if you use REST calls only to update the state of your location once and then use the real time API to stay in sync (see sections below for more information).
If you feel your application absolutely cannot adhere to these limits and your use case is interesting for Gardena, please get in touch to see whether we can grant you higher rate limits.

## Health Check

To make sure the API is up and running, _you mustn't use a regular endpoint_, as you would run into the rate limiting quickly. 
Instead, use the dedicated health check endpoint that doesn't need an API key and operates with very high limits:

* `GET /health`

A return code of `200` means everything is ok and the API is ready to respond to requests.

## Realtime API

To make sure you have an up-to-date state at every point in time, you have two options:

* open a [Websocket](#using-websockets) for the location in question
* register a [Webhook](#using-webhooks) for the location you are interested in

Both websockets and webhooks use the same event format, see [Rules of events processing](#rules-of-events-processing)

### Using websockets

  1. Get the location ID using the `GET /locations` REST endpoint.
  2. Reset your internal state.
  3. Get the websocket URL using the `POST /websocket` REST endpoint. Note that for security reasons the URL is only 
     valid for a few seconds.
  4. Open a websocket connection using the obtained URL.
     1. Since the websocket is closed automatically after 10 minutes of inactivity, we recommend sending ping messages every 150 seconds to keep the connection open. 
     2. Also, websocket connections have a max duration of 2 hours. This is to allow effective load balancing on the server.
  5. Consider every websocket event as a PATCH operation towards your internal state (details see 
     [Rules of events processing](#rules-of-events-processing)).
     It is important that you process each object you get over the websocket channel. If you only limit yourself
     to processing certain documents, you will inevitably end up in a situation where your local state
     mismatches the actual one.
  6. If the websocket connection is terminated - proceed with step 2.

### Sample websocket client 
The following Python example shows how to open a websocket connection and process events. Note that we set a ping
interval of 150 seconds, to prevent the websocket connection from being closed automatically.

#### Setup
Make sure to have Python as well as pip installed.

```bash
$ sudo apt-get install python3 
$ sudo apt-get install python3-pip
```

The code has external dependencies to the requests and websocket-client packages. Install them as follows

```bash
$ pip3 install requests
$ pip3 install websocket-client
```

The script has been tested successfully with the following versions of the dependencies:

* `python --version`: 
  * 3.7.3 
  * 3.7.4
  * 3.10.0
* `pip3 --version`:
  * pip 18.1 from /usr/lib/python3/dist-packages/pip (python 3.7)
  * pip 20.2.4 from /Users/dev/opt/anaconda3/lib/python3.7/site-packages/pip (python 3.7)
  * pip 21.3.1 from /usr/local/lib/python3.10/site-packages/pip (python 3.10)
* `pip3 show requests`:
  * 2.22.0
* `pip3 show websocket-client`:
  * 1.1.0

#### Script

The python script below can be used to open a websocket connection and output delivered events. Make sure to replace the placeholders in the script with the values you got while registering your application on the developer portal:

```python
CLIENT_ID = '<YOUR_CLIENT_ID>'
CLIENT_SECRET = '<YOUR_CLIENT_SECRET>'
API_KEY = '<YOUR_API_KEY>'
```

Copy the code-snipped below into a file e.g. `ws_test.py`, replace the placeholders above, and run it with python3: 

```python
python ws_test.py
```

If you get errors, make sure you use the same dependency versions as stated above.

```python
import websocket
import datetime
from threading import Thread
import time
import sys
import requests

# account specific values
CLIENT_ID = '<YOUR_CLIENT_ID>'
CLIENT_SECRET = '<YOUR_CLIENT_SECRET>'
API_KEY = '<YOUR_API_KEY>'

# other constants
AUTHENTICATION_HOST = 'https://api.authentication.husqvarnagroup.dev'
SMART_HOST = 'https://api.smart.gardena.dev'

class Client:
    def on_message(self, ws, message):
        x = datetime.datetime.now()
        print("msg ", x.strftime("%H:%M:%S,%f"))
        print(message)
        sys.stdout.flush()

    def on_error(self, ws, error):
        x = datetime.datetime.now()
        print("error ", x.strftime("%H:%M:%S,%f"))
        print(error)

    def on_close(self, ws, close_status_code, close_msg):
        self.live = False
        x = datetime.datetime.now()
        print("closed ", x.strftime("%H:%M:%S,%f"))
        print("### closed ###")
        if close_status_code:
            print("status code: "+close_status_code)
        if close_msg:
            print("status message: "+close_msg)
        sys.exit(0)

    def on_open(self, ws):
        x = datetime.datetime.now()
        print("connected ", x.strftime("%H:%M:%S,%f"))
        print("### connected ###")

        self.live = True

        def run(*args):
            while self.live:
                time.sleep(1)

        Thread(target=run).start()

def format(response):
    formatted = [response.url, "%s %s" % (response.status_code, response.reason)]
    for k,v in response.headers.items():
        formatted.append("%s: %s" % (k, v))
    formatted.append("")
    formatted.append(r.text)
    return "\n".join(formatted)


if __name__ == "__main__":
    payload = {'grant_type': 'client_credentials', 'client_id': CLIENT_ID, 'client_secret': CLIENT_SECRET}

    print("Logging into authentication system...")
    r = requests.post(f'{AUTHENTICATION_HOST}/v1/oauth2/token', data=payload)
    assert r.status_code == 200, format(r)
    auth_token = r.json()["access_token"]
    print("Logged in auth_token=(%s)" % auth_token)

    headers = {
        "Content-Type": "application/vnd.api+json",
        "x-api-key": API_KEY,
        "Authorization": "Bearer " + auth_token
    }

    print("### get locations ###")
    r = requests.get(f'{SMART_HOST}/v1/locations', headers=headers)
    assert r.status_code == 200, format(r)
    assert len(r.json()["data"]) > 0, 'location missing - user has not setup system'
    location_id = r.json()["data"][0]["id"]
    print("LocationId=(%s)" % location_id)


    payload = {
        "data": {
            "type": "WEBSOCKET",
            "attributes": {
                "locationId": location_id
            },
            "id": "does-not-matter"
        }
    }
    print("getting websocket ID...")
    r = requests.post(f'{SMART_HOST}/v1/websocket', json=payload, headers=headers)

    assert r.status_code == 201, format(r)
    print("Websocket ID obtained, connecting...")
    response = r.json()
    websocket_url = response["data"]["attributes"]["url"]

    websocket.enableTrace(True)
    client = Client()
    ws = websocket.WebSocketApp(
        websocket_url,
        on_message=client.on_message,
        on_error=client.on_error,
        on_close=client.on_close)
    ws.on_open = client.on_open
    ws.run_forever(ping_interval=150, ping_timeout=1)
```
### Using Webhooks

You can use the REST API to register an url ("webhook") for a location to which the Smart System then will post update events for all devices in the location of interest.
Do this by registering an url (that must be public and should be stable) using the `POST /webhook` endpoint.

#### Security
In order to protect your webhook endpoint against attacks, we offer the possibility to check received payloads on integrity by implementing the HMAC 256 check. This works as follows:

1. You need to store the `hmacSecret` which is provided when registering a location for webhooks on `POST /webhook`
2. We compute the HMAC signature which belongs to the serialized payload and add it to the custom header
   * the header is called: `X-Authorization-Content-SHA256`
   * the encoding of the signature is: `hex`-string
3. On getting the event, you need to compute tha HMAC signature by yourself
   1. use the raw payload of the request as input
      1. make sure, that your framework of choice does not automatically map or modify the payload in any way, as this would change the resulting signature 
   2. use the `hmacSecret` without any changes in encoding i.e. as regular string type
   3. compare the `hex` signature you get in the header of the request to the `hex` encoded signature you have created yourself with the `hmacSecret`. 

To do it in JavaScript, for example use `hash.js` which outputs a `hex`-string too.

```javascript
var hash = require('hash.js')

var isValidHmac = (input, secret, signature)=>{
    const hexKey = Buffer.from(secret, 'utf8').toString('hex')
    const hexMsg = Buffer.from(input, 'utf8').toString('hex')
    const hmac = hash.hmac(hash.sha256, hexKey, 'hex').update(hexMsg, 'hex').digest('hex')
    return signature === hmac
}

const input = "The quick brown fox jumps over the lazy dog"
const secret =  "key"
const signature = "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8"

console.log(isValidHmac(input, secret, signature));
```

#### Expiration

Registered urls will only stay valid for the period specified by the `validUntil` property of the `POST` response. To keep a webhook alive, you need to `POST` again within the expiration time of the webhook.

#### Deleting webhooks

If you don't want to receive events anymore you can remove the webhook manually. use the `DELETE` webhook as described in the API documentation.

### Rules of events processing

The API follows the [{JSON:API}](https://jsonapi.org/) standard. That is: all objects are linked to each other in
an unambiguous way and each PATCH operation is partial, only changing the fields that are explicitly mentioned.

Example:

* Internal model before event

```json
{
  "id": "some-id", 
  "type": "SOME_TYPE",
  "data": {
    "a": 1, 
    "b": ["foo", "bar"], 
    "c": 2
  }
}
```

* PATCH event

```json
{
  "id": "some-id", 
  "type": "SOME_TYPE",
  "data": {
    "b": ["bar", "baz"], 
    "c": null, 
    "d": 3
  }
}
```

* Internal model after event

```json
{
  "id": "some-id", 
  "type": "SOME_TYPE",
  "data": {
    "a": 1, 
    "b": ["bar", "baz"], 
    "d": 3
  }
}
```

### Used document types
In Realtime API, you will receive the following document types:

* `SENSOR`
* `VALVE`
* `VALVE_SET`
* `POWER_SOCKET`
* `MOWER`
* `COMMON`

The updates MIGHT be partial (only including the properties that changed) and that is why it is important that clients maintain their internal state.

#### Differences in payload delivery: websockets vs webhooks

* Websockets: payloads are delivered as the pure document types specified above. For each document type, a single message is sent to the websocket.
* Webhooks: interactions that trigger multiple events of different document types are sent as a single { JSON:API } document with the following structure:

```json
{
  "data": {
    "attributes": {
      "location-id": "e1840725-c965-42ac-9664-c5708e12eff4",
      "events": [
        <payload for document type e.g. VALVE_SET>,
        <payload for document type e.g. VALVE>,
        <payload for document type e.g. COMMON>
      ]
    },
    "id": "f670ec78-7413-4eb6-b575-c29e4377e4ce",
    "type": "WEBHOOK"
  }
}
```


### Location out of sync

If the location is out of sync (i.e. a device has been added to the location after the websocket has been opened or a webhook has been registered) the following will happen:

* Any websocket on the location in question is closed and has to be reopened by the user. When opening a websocket, the state for the complete location is dumped to it, therefore also including information on any additional devices. 
* Webhooks remain registered but won't get events for the newly included device. It is therefore necessary to get the location state again using a REST request.

We might change this behaviour in a future version of the API and provide events for included and removed devices.
