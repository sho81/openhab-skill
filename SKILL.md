---
name: openhab
description: Control openHAB smart home devices, run automations, and receive webhook events. Use when controlling lights, switches, climate, scenes, scripts, or any openHAB entity. Supports bidirectional communication via REST API (outbound) and webhooks (inbound triggers from openHAB automations).
metadata: {"clawdbot":{"emoji":"🏠","requires":{"bins":["jq","curl"]}}}
---

# openHAB

Control your smart home via openHAB's REST API and webhooks.

## Setup

### Option 1: Config File (Recommended)

Create `~/.config/openhab/config.json`:
```json
{
  "url": "https://your-openhab-instance.duckdns.org",
  "token": "your-long-lived-access-token"
}
```

### Option 2: Environment Variables

```bash
export OPENHAB_URL="http://openhab.local:8080"
export OPENHAB_TOKEN="your-long-lived-access-token"
```

### Getting a Long-Lived Access Token

1. Open openHAB → Profile (bottom left)
2. Scroll to "Long-Lived Access Tokens"
3. Click "Create Token", name it (e.g., "Clawdbot")
4. Copy the token immediately (shown only once)

## Quick Reference

### List Entities

```bash
curl -s -H -X GET -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Accept: application/json" "${OPENHAB_URL}/rest/items?recursive=false"| jq '.[].name'
```

### Get Entity State
Checking state of item_name
```bash

curl -X GET -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Accept: text/plain" "${OPENHAB_URL}/rest/items/item_name/state"
```

### Control Devices

```bash
# Turn on item_name
curl -X 'POST' -H 'accept: */*' -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Content-Type: text/plain" "${OPENHAB_URL}/rest/items/item_name" -d 'ON'

# Turn off item_name
curl -X 'POST' -H 'accept: */*' -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Content-Type: text/plain"  "${OPENHAB_URL}/rest/items/item_name" -d 'ON'



### 3. Handle in Clawdbot

Clawdbot receives the webhook and can notify you or take action based on the event.

## CLI Wrapper

The `scripts/ha.sh` CLI provides easy access to all HA functions:

```bash
# Test connection
ha.sh info

# List entities
ha.sh list all          # all entities
ha.sh list lights       # just lights
ha.sh list switch       # just switches

# Search entities
ha.sh search kitchen    # find entities by name

# Get/set state
ha.sh state light.living_room
ha.sh states light.living_room   # full details with attributes
ha.sh on light.living_room
ha.sh on light.living_room 200   # with brightness (0-255)
ha.sh off light.living_room
ha.sh toggle switch.fan

# Scenes & scripts
ha.sh scene movie_night
ha.sh script goodnight

# Climate
ha.sh climate climate.thermostat 22

# Call any service
ha.sh call light turn_on '{"entity_id":"light.room","brightness":200}'
```

## Troubleshooting

- **401 Unauthorized**: Token expired or invalid. Generate a new one.
- **Connection refused**: Check HA_URL, ensure HA is running and accessible.
- **Entity not found**: List entities to find the correct entity_id.

## API Reference

For advanced usage, see [references/api.md](references/api.md).
