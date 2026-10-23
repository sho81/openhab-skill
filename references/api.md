# openHAB REST API Reference

> **Tested against:** openHAB **5.2.1** (Release Build), REST API version 8, OpenAPI 3.0.1 specification.
> The full machine-readable spec is served by the instance itself at `GET ${OPENHAB_URL}/rest/spec` — it is the same document MainUI's *Developer → API Explorer* renders. Consult it for endpoints beyond this reference.

## Authentication

All requests require a long-lived access token, passed either as:

```
Authorization: Bearer <long-lived-access-token>
```

or equivalently in the custom header `X-OPENHAB-TOKEN: <token>`.

Token scopes limit which resources are visible — create tokens with only the scopes you need (`Items` is enough for item state; add `Things`, `Channels`, `Rules`, … as required).

## Discovery

```bash
# Runtime info, API version and links to all resource endpoints
curl -X GET "${OPENHAB_URL}/rest/" -H "Authorization: Bearer <token>"

# Full OpenAPI 3.0 specification (JSON)
curl -X GET "${OPENHAB_URL}/rest/spec" -H "Authorization: Bearer <token>"
```

## Endpoints used by this skill

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Runtime info, API version, links to resources |
| `/spec` | GET | Full OpenAPI 3.0 specification (JSON) |
| `/items` | GET | Get all available items (query: `type`, `tags`, `recursive`, …) |
| `/items/{itemName}` | GET | Get a single item |
| `/items/{itemName}/state` | GET | Get the state of an item (plain text) |
| `/items/{itemName}` | POST | Send a command to an item |
| `/items/{itemName}/state` | PUT | Update the state of an item without commanding the device |
| `/things` | GET | Get all available things (`?summary=true` for a compact list) |
| `/things/{thingUID}` | GET | Get a thing by UID (includes channels and linked items) |
| `/things/{thingUID}/status` | GET | Get online status of a Thing |
| `/links` | GET | Get all item↔channel links (`?itemName=`, `?channelUID=` filters) |

Naming rules: item names match `[a-zA-Z_0-9]+`; Thing UIDs have the form `binding:thingType:uid`. Colons in Thing UIDs may be left unencoded in URLs.

## Other endpoint families (see `/rest/spec`)

The full API covers 177 operations across these resource families: rules, items, voice, sitemaps, persistence, addons, file-format, links, ui, services, auth, inbox/discovery/transformations/tags/logging, plus single endpoints for audio, events, iconsets, module-types, profile-types, systeminfo and uuid.

## Common Operations

### List Items

```bash
# Get all items
curl -X GET "${OPENHAB_URL}/rest/items" -H "Authorization: Bearer <token>" -H "Accept: application/json"

# Get items recursively (without members of groups)
curl -X GET "${OPENHAB_URL}/rest/items?recursive=false" -H "Authorization: Bearer <token>" -H "Accept: application/json"
```

### Get Item State

```bash
# Get state as plain text
curl -X GET "${OPENHAB_URL}/rest/items/LivingRoom_Light/state" -H "Authorization: Bearer <token>" -H "Accept: text/plain"
```

### Send Command to Item

Commands are sent using `POST` to the item endpoint. The body should be plain text containing the command (e.g., `ON`, `OFF`, `50`). Optionally identify your app with the `X-OpenHAB-Source` header.

```bash
# Turn on a switch or light
curl -X POST "${OPENHAB_URL}/rest/items/LivingRoom_Light" -H "Authorization: Bearer <token>" -H "Content-Type: text/plain" -d "ON"

# Set a dimmer to 50%
curl -X POST "${OPENHAB_URL}/rest/items/Living_Room_Dimmer" -H "Authorization: Bearer <token>" -H "Content-Type: text/plain" -d "50"
```

### Update Item State

State updates are sent using `PUT` to the item state endpoint. This updates the state in openHAB without sending a command to the physical device.

```bash
curl -X PUT "${OPENHAB_URL}/rest/items/LivingRoom_Light/state" -H "Authorization: Bearer <token>" -H "Content-Type: text/plain" -d "ON"
```

### Thing Status (online/offline)

Thing UIDs have the form `binding:thingType:uid` (e.g., `mybinding:MyThingType:abc123`). Colons may be left unencoded in the URL.

```bash
curl -X GET "${OPENHAB_URL}/rest/things/mybinding:MyThingType:abc123/status" -H "Authorization: Bearer <token>" -H "Accept: application/json"
# → {"status":"ONLINE","statusDetail":"NONE"}
```

### Get Thing by UID

Returns the full thing including its channels and linked items. Note that `configuration` may contain credentials — don't log it verbatim.

```bash
curl -X GET "${OPENHAB_URL}/rest/things/mybinding:MyThingType:abc123" -H "Authorization: Bearer <token>" -H "Accept: application/json"
```

## Item Object

```json
{
  "link": "${OPENHAB_URL}/rest/items/LivingRoom_Light",
  "state": "ON",
  "stateDescription": {
    "pattern": "%s",
    "readOnly": false,
    "options": []
  },
  "lastState": "OFF",
  "lastStateUpdate": 1792780863631,
  "lastStateChange": 1792780863631,
  "unitSymbol": "",
  "metadata": {},
  "editable": false,
  "type": "Switch",
  "name": "LivingRoom_Light",
  "label": "Living Room Light",
  "category": "light",
  "tags": [
    "Lighting"
  ],
  "groupNames": []
}
```

## Thing Object

```json
{
  "UID": "mybinding:MyThingType:abc123",
  "thingTypeUID": "mybinding:MyThingType",
  "label": "My Device",
  "location": "",
  "semanticEquipmentTag": "",
  "statusInfo": {
    "status": "ONLINE",
    "statusDetail": "NONE"
  },
  "channels": [
    {
      "uid": "mybinding:MyThingType:abc123:somechannel",
      "linkedItems": ["MyDevice_SomeChannel"]
    }
  ],
  "configuration": {},
  "properties": {},
  "editable": true
}
```

### Thing Status Values

`statusInfo.status`: `UNINITIALIZED`, `INITIALIZING`, `UNKNOWN`, `ONLINE`, `OFFLINE`, `REMOVING`, `REMOVED`.

`statusInfo.statusDetail` (reason, when not `NONE`): `NOT_YET_READY`, `HANDLER_MISSING_ERROR`, `HANDLER_REGISTERING_ERROR`, `HANDLER_INITIALIZING_ERROR`, `HANDLER_CONFIGURATION_PENDING`, `CONFIGURATION_PENDING`, `COMMUNICATION_ERROR`, `CONFIGURATION_ERROR`, `BRIDGE_OFFLINE`, `FIRMWARE_UPDATING`, `DUTY_CYCLE`, `BRIDGE_UNINITIALIZED`, `GONE`, `DISABLED`.

## Error Responses

| Code | Meaning |
|------|---------|
| 400 | Bad request |
| 401 | Unauthorized (invalid/missing token) |
| 404 | Resource not found — openHAB returns an **empty body** for missing resources and unknown paths |
| 405 | Method not allowed |
