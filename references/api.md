# openHAB REST API Reference

## Authentication

All requests require the `Authorization` header:

```
Authorization: Bearer <long-lived-access-token>
```

## Base Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/rest/items` | GET | Get all available items |
| `/rest/items/{itemname}` | GET | Get a single item |
| `/rest/items/{itemname}/state` | GET | Get the state of an item |
| `/rest/items/{itemname}` | POST | Send a command to an item |
| `/rest/items/{itemname}/state` | PUT | Update the state of an item |
| `/rest/things` | GET | Get all available things |
| `/rest/links` | GET | Get all available links |
| `/rest/rules` | GET | Get all available rules |

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

Commands are sent using `POST` to the item endpoint. The body should be plain text containing the command (e.g., `ON`, `OFF`, `50`).

```bash
# Turn on a switch or light
curl -X POST "${OPENHAB_URL}/rest/items/LivingRoom_Light" -H "Authorization: Bearer <token>" -H "Content-Type: text/plain" -d "ON"

# Set a dimmer to 50%
curl -X POST "${OPENHAB_URL}/rest/items/LivingRoom_Dimmer" -H "Authorization: Bearer <token>" -H "Content-Type: text/plain" -d "50"
```

### Update Item State

State updates are sent using `PUT` to the item state endpoint. This updates the state in openHAB without sending a command to the physical device.

```bash
curl -X PUT "${OPENHAB_URL}/rest/items/LivingRoom_Light/state" -H "Authorization: Bearer <token>" -H "Content-Type: text/plain" -d "ON"
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
  "editable": false,
  "type": "Switch",
  "name": "LivingRoom_Light",
  "label": "Living Room Light",
  "category": "light",
  "tags": [
    "Lighting"
  ],
  "groupNames": [
    "LivingRoom"
  ]
}
```

## Error Responses

| Code | Meaning |
|------|---------|
| 400 | Bad request |
| 401 | Unauthorized (invalid/missing token) |
| 404 | Item not found |
| 405 | Method not allowed |
