# openHAB Skill for AI Agents

This repository provides a skill for AI agents to control openHAB smart home devices, run automations, and receive webhook events. It supports bidirectional communication via the openHAB REST API (outbound) and webhooks (inbound triggers from openHAB automations).

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
  "url": "http://your-openhab-instance:8080",
  "token": "your-long-lived-access-token"
}
```

### Option 2: Environment Variables

Alternatively, you can set the following environment variables:

```bash
export OPENHAB_URL="http://your-openhab-instance:8080"
export OPENHAB_TOKEN="your-long-lived-access-token"
```

### Getting a Long-Lived Access Token

1. Open your openHAB dashboard.
2. Go to your **Profile** (bottom left corner).
3. Scroll down to the **"Long-Lived Access Tokens"** section.
4. Click **"Create Token"**, give it a name (e.g., "AI Agent").
5. Copy the token immediately (it will only be shown once).

## CLI Wrapper

The `scripts/oa.sh` CLI provides easy access to openHAB functions from the terminal:

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

## Troubleshooting

- **401 Unauthorized**: Your token has expired or is invalid. Generate a new one from your openHAB profile.
- **Connection refused**: Check the `OPENHAB_URL` in your configuration and ensure your openHAB instance is running and accessible.
- **Entity not found**: Use the `list` command to find the correct item name.

## API Reference

For advanced usage and details about the openHAB REST API, see [references/api.md](references/api.md).
