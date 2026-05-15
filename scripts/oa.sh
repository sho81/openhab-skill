#!/usr/bin/env bash
# openhab CLI wrapper
# Usage: oa.sh <command> [args...]

set -euo pipefail

CONFIG_FILE="${HA_CONFIG:-$HOME/.config/openhab/config.json}"

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
  OPENHAB_URL="${OPENHAB_URL:-$(jq -r '.url // empty' "$CONFIG_FILE")}"
  OPENHAB_TOKEN="${OPENHAB_TOKEN:-$(jq -r '.token // empty' "$CONFIG_FILE")}"
fi

: "${OPENHAB_URL:?Set OPENHAB_URL or configure $CONFIG_FILE}"
: "${OPENHAB_TOKEN:?Set OPENHAB_TOKEN or configure $CONFIG_FILE}"

cmd="${1:-help}"
shift || true

api() {
  curl -s -H "Authorization: Bearer $OPENHAB_TOKEN" -H "Content-Type: application/json" "$@"
}

case "$cmd" in
  state|get)
    # Get item state: oa.sh state living_room
    item="${1:?Usage: oa.sh state <item_id>}"
    curl -X GET -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Accept: text/plain" "${OPENHAB_URL}/rest/items/${item}/state"
    ;;

  attributes)
  # Get item state: oa.sh state living_room
    item="${1:?Usage: oa.sh state <item_id>}"
    curl -X GET -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Accept: application/json" "${OPENHAB_URL}/rest/items/${item}" | jq
    ;;

  on|turn_on)
    # Turn on item: oa.sh on living_room 
    item="${1:?Usage: oa.sh on <item_id> }"

    curl -X 'POST' -H 'accept: */*' -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Content-Type: text/plain" "${OPENHAB_URL}/rest/items/${item}" -d 'ON'
    
    echo "✓ $item turned on"
    ;;

  off|turn_off)
    # Turn off item: oa.sh on living_room 
    item="${1:?Usage: oa.sh on <item_id> }"

    curl -X 'POST' -H 'accept: */*' -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Content-Type: text/plain" "${OPENHAB_URL}/rest/items/${item}" -d 'OFF'
    
    echo "✓ $item turned off"
    ;;

 
  list)
    # List entities by type: oa.sh list Switch / oa.sh list all
    filter="${1:-all}"
    if [[ "$filter" == "all" ]]; then
      curl -s -X GET -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Accept: application/json" "${OPENHAB_URL}/rest/items?recursive=false"| jq -r '.[].name' | sort
    else
      # Normalize: "lights" -> "light", "switches" -> "switch"
      filter="${filter%s}"
      curl -s -X GET -H "Authorization: Bearer ${OPENHAB_TOKEN}" -H "Accept: application/json" "${OPENHAB_URL}/rest/items?recursive=false" | jq -r --arg d "$filter" \
        '.[] | select(.type | test($d; "i")) | .name' | sort
    fi
    ;;

  help|*)
    cat <<EOF
openHAB CLI

Usage: oa.sh <command> [args...]

Commands:
  state <item>              Get item state
  attributes <item>         Get full item state with attributes
  on <item>                 Turn on 
  off <item>                Turn off
  list [type]               List items (e.g., all, Switch, Dimmer)

Environment:
  OPENHAB_URL    openHAB URL (required)
  OPENHAB_TOKEN  Long-lived access token (required)

Examples:
  oa.sh on LivingRoom_Light
  oa.sh list Switch
EOF
    ;;
esac
