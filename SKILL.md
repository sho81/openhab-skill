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

### Getting an API Token

1. Sign in to openHAB with your administrator username and password (bottom left).
2. Click again on the profile button to access your profile page.
3. Click on "Create new API token".
4. Enter your admin username and password, fill in the token name (e.g., "AI Agent"), and select a Token Scope.
5. Copy the complete token immediately (it will only be shown once).

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

The `scripts/oa.sh` CLI provides easy access to openHAB functions:

```bash
# List entities
oa.sh list all          # all entities
oa.sh list Switch       # just switches
oa.sh list Dimmer       # just dimmers

# Get/set state
oa.sh state LivingRoom_Light
oa.sh attributes LivingRoom_Light   # full details with attributes
oa.sh on LivingRoom_Light
oa.sh off LivingRoom_Light
```

## Troubleshooting

- **401 Unauthorized**: Token expired or invalid. Generate a new one.
- **Connection refused**: Check OPENHAB_URL, ensure openHAB is running and accessible.
- **Entity not found**: List entities to find the correct item name.

## API Reference

For advanced usage, see [references/api.md](references/api.md).
