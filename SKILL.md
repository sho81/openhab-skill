---
name: openhab
description: Control openHAB smart home devices, run automations, and receive webhook events. Use when controlling lights, switches, climate, scenes, scripts, or any openHAB entity. Supports bidirectional communication via REST API (outbound) and webhooks (inbound triggers from openHAB automations).
---

# openHAB

Control your smart home via openHAB's REST API and webhooks.

## Setup

### Option 1: Config File (Recommended)

Create a configuration file at `~/.config/openhab/config.json` (or set `HA_CONFIG` to point to your config file):
```json
{
  "url": "https://your-openhab-instance.duckdns.org",
  "token": "your-long-lived-access-token"
}
```

The file contains your token, so restrict its permissions:

```bash
chmod 600 ~/.config/openhab/config.json
```

### Option 2: Environment Variables

```bash
export OPENHAB_URL="http://openhab.local:8080"
export OPENHAB_TOKEN="your-long-lived-access-token"
```

> **TLS:** over plain HTTP the token and all states travel in cleartext — acceptable on a trusted LAN, but prefer HTTPS for anything beyond it. For self-signed certificates pass `--cacert /path/to/ca.crt` to curl; avoid `-k`, which disables verification entirely.

### Getting an API Token

1. Sign in to openHAB with your administrator username and password (bottom left).
2. Click again on the profile button to access your profile page.
3. Click on "Create new API token".
4. Enter your admin username and password, fill in the token name (e.g., "AI Agent"), and select the narrowest Token Scope that works — `Items` is enough for this skill.
5. Copy the complete token immediately (it will only be shown once).

> **Least privilege:** consider a dedicated non-admin user with an Items-only scope instead of your admin account. If openHAB is exposed to the internet (e.g., via duckdns), put it behind a reverse proxy with TLS and consider IP allowlisting.

## Quick Reference

### List Entities

```bash
curl -s -X GET -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Accept: application/json" "${OPENHAB_URL}/rest/items?recursive=false" | jq '.[].name'
```

### Get Entity State

```bash
curl -X GET -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Accept: text/plain" "${OPENHAB_URL}/rest/items/item_name/state"
```

### Control Devices

```bash
# Turn on item_name
curl -X 'POST' -H 'accept: */*' -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Content-Type: text/plain" "${OPENHAB_URL}/rest/items/item_name" -d 'ON'

# Turn off item_name
curl -X 'POST' -H 'accept: */*' -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Content-Type: text/plain" "${OPENHAB_URL}/rest/items/item_name" -d 'OFF'
```

## Webhooks (Inbound)

openHAB can push events to your agent instead of polling: create an openHAB rule with an HTTP action that POSTs a JSON payload to your agent's webhook endpoint when something happens (e.g., a motion sensor triggers):

```json
{
  "item": "Motion_Hallway",
  "state": "ON"
}
```

The agent receives the event and can notify you or trigger further actions.

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
