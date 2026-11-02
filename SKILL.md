---
name: openhab
description: Control openHAB smart home devices and receive webhook events. Use when controlling lights, switches, climate, scenes, scripts, or any openHAB entity. Supports bidirectional communication via REST API (outbound) and webhooks (inbound triggers from openHAB automations).
---

# openHAB

Control your smart home via openHAB's REST API and webhooks.

> **Scope:** This skill only reads and commands Items and reads Thing status. It does **not** run openHAB rules/automations (no `/rest/rules` support); openHAB automations can push events to the agent via webhooks (see below), but cannot be triggered from it.

## Disclaimer

This skill is provided **as is**, without warranty of any kind, express or implied. It is a convenience wrapper around the openHAB REST API — not production-grade software and not intended for production use. **Use at your own risk.** See [LICENSE](LICENSE) for legal details.

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

### Get Channel Value

Channels are addressed as `binding:type:uid:channel` (four parts, vs. three for a Thing UID). A channel's value lives on its linked item(s), so resolve channel → item via the thing JSON first — the sub-resource `/rest/things/<thingUID>/channels` may 404 depending on instance or token scope:

```bash
# Resolve channel to its linked item name(s)
curl -s -H "Authorization: Bearer ${OPENHAB_TOKEN}" "${OPENHAB_URL}/rest/things/binding:type:uid" \
  | jq -r '.channels[] | select(.id=="channel_id") | .linkedItems[]'

# Then read the state as usual (see Get Entity State)
curl -s -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Accept: text/plain" "${OPENHAB_URL}/rest/items/<item_name>/state"
```

### Thing Status (online/offline)

```bash
curl -X GET -H "Authorization: Bearer ${OPENHAB_TOKEN}" "${OPENHAB_URL}/rest/things/thing_uid/status"
# → {"status":"ONLINE","statusDetail":"NONE"}
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

The `scripts/openhab.sh` CLI provides easy access to openHAB functions:

```bash
# List entities
openhab.sh list all          # all entities
openhab.sh list Switch       # just switches
openhab.sh list Dimmer       # just dimmers

# Get/set state
openhab.sh state LivingRoom_Light
openhab.sh attributes LivingRoom_Light   # full details with attributes
openhab.sh on LivingRoom_Light
openhab.sh off LivingRoom_Light

# Thing online status (Thing UID = binding:type:uid)
openhab.sh thing-status mybinding:MyThingType:abc123
```

## Troubleshooting

- **401 Unauthorized**: Token expired or invalid. Generate a new one.
- **Connection refused**: Check OPENHAB_URL, ensure openHAB is running and accessible.
- **Entity not found**: List entities to find the correct item name.

## API Reference

For advanced usage, see [references/api.md](references/api.md).
