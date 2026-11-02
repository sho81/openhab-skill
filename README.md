# openHAB Skill for AI Agents

This repository provides a skill for AI agents to control openHAB smart home devices and receive webhook events. It supports bidirectional communication via the openHAB REST API (outbound) and webhooks (inbound triggers from openHAB automations).

> **Not supported (yet):** Running openHAB rules/automations. The skill reads and commands Items and reads Thing status; triggering rules via the API is not implemented.

Forked from [ElDuderinos/openhab-skill](https://github.com/ElDuderinos/openhab-skill) by @ElDuderinos — see [LICENSE](LICENSE) for copyright details.

## Disclaimer

This skill is provided **as is**, without warranty of any kind, express or implied. It is a convenience wrapper around the openHAB REST API — not production-grade software and not intended for production use. **Use at your own risk.** See [LICENSE](LICENSE) for legal details.

## Features

- Control lights, switches, climate, scenes, scripts, or any openHAB entity.
- List and search for available items.
- Get the current state and attributes of any item.
- Easy-to-use CLI wrapper (`scripts/oa.sh`) for manual testing and interaction.

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

Alternatively, you can set the following environment variables:

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


## CLI Wrapper

The `scripts/oa.sh` CLI provides easy access to openHAB functions from the terminal. It requires `jq` and `curl`:

```bash
# List entities
oa.sh list all          # List all entities
oa.sh list Switch       # List only switches
oa.sh list Dimmer       # List only dimmers

# Get/set state
oa.sh state LivingRoom_Light
oa.sh attributes LivingRoom_Light   # Get full details with attributes
oa.sh on LivingRoom_Light
oa.sh off LivingRoom_Light
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

## Troubleshooting

- **401 Unauthorized**: Your token has expired or is invalid. Generate a new one from your openHAB profile.
- **Connection refused**: Check the `OPENHAB_URL` in your configuration and ensure your openHAB instance is running and accessible.
- **Entity not found**: Use the `list` command to find the correct item name.

## API Reference

For advanced usage and details about the openHAB REST API, see [references/api.md](references/api.md).
