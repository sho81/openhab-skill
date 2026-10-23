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

for dep in jq curl; do
  command -v "$dep" >/dev/null || { echo "✗ required dependency '$dep' not found in PATH" >&2; exit 1; }
done

# Timeouts so a hung instance doesn't block the CLI/agent forever (M5)
CURL_OPTS=(--connect-timeout 5 --max-time 10)

# Keep the token out of curl's argv (visible via ps); mktemp creates with mode 600 (M2)
AUTH_FILE=$(mktemp) || exit 1
trap 'rm -f "$AUTH_FILE"' EXIT
printf 'Authorization: Bearer %s\n' "$OPENHAB_TOKEN" > "$AUTH_FILE"

cmd="${1:-help}"
shift || true

case "$cmd" in
  state|get)
    # Get item state: oa.sh state living_room
    item="${1:?Usage: oa.sh state <item_id>}"
    [[ "$item" =~ ^[A-Za-z0-9_]+$ ]] || { echo "✗ invalid item name '$item' (expected [A-Za-z0-9_])" >&2; exit 1; }
    curl "${CURL_OPTS[@]}" -X GET -H @"$AUTH_FILE" -H "Accept: text/plain" "${OPENHAB_URL}/rest/items/${item}/state"
    ;;

  attributes)
    # Get item attributes: oa.sh attributes living_room
    item="${1:?Usage: oa.sh attributes <item_id>}"
    [[ "$item" =~ ^[A-Za-z0-9_]+$ ]] || { echo "✗ invalid item name '$item' (expected [A-Za-z0-9_])" >&2; exit 1; }
    curl "${CURL_OPTS[@]}" -X GET -H @"$AUTH_FILE" -H "Accept: application/json" "${OPENHAB_URL}/rest/items/${item}" | jq
    ;;

  thing-status)
    # Get Thing online status: oa.sh thing-status mybinding:MyThingType:abc123
    uid="${1:?Usage: oa.sh thing-status <thing_uid>}"
    [[ "$uid" =~ ^[A-Za-z0-9]+:[A-Za-z0-9_:-]+$ ]] || { echo "✗ invalid Thing UID '$uid' (expected binding:type:uid)" >&2; exit 1; }
    curl "${CURL_OPTS[@]}" -s -X GET -H @"$AUTH_FILE" -H "Accept: application/json" "${OPENHAB_URL}/rest/things/${uid}/status" | jq
    ;;

  on|turn_on)
    # Turn on item: oa.sh on living_room
    item="${1:?Usage: oa.sh on <item_id>}"
    [[ "$item" =~ ^[A-Za-z0-9_]+$ ]] || { echo "✗ invalid item name '$item' (expected [A-Za-z0-9_])" >&2; exit 1; }

    http_code=$(curl "${CURL_OPTS[@]}" -s -o /dev/null -w '%{http_code}' -X POST -H "Accept: */*" -H @"$AUTH_FILE" -H "Content-Type: text/plain" "${OPENHAB_URL}/rest/items/${item}" -d 'ON')
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
      echo "✓ $item turned on"
    else
      echo "✗ failed to turn on $item (HTTP $http_code)" >&2
      exit 1
    fi
    ;;

  off|turn_off)
    # Turn off item: oa.sh off living_room
    item="${1:?Usage: oa.sh off <item_id>}"
    [[ "$item" =~ ^[A-Za-z0-9_]+$ ]] || { echo "✗ invalid item name '$item' (expected [A-Za-z0-9_])" >&2; exit 1; }

    http_code=$(curl "${CURL_OPTS[@]}" -s -o /dev/null -w '%{http_code}' -X POST -H "Accept: */*" -H @"$AUTH_FILE" -H "Content-Type: text/plain" "${OPENHAB_URL}/rest/items/${item}" -d 'OFF')
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
      echo "✓ $item turned off"
    else
      echo "✗ failed to turn off $item (HTTP $http_code)" >&2
      exit 1
    fi
    ;;

  list)
    # List entities by type: oa.sh list Switch / oa.sh list all
    filter="${1:-all}"
    if [[ "$filter" == "all" ]]; then
      curl "${CURL_OPTS[@]}" -s -X GET -H @"$AUTH_FILE" -H "Accept: application/json" "${OPENHAB_URL}/rest/items?recursive=false"| jq -r '.[].name' | sort
    else
      # Normalize: "lights" -> "light", "switches" -> "switch"
      filter="${filter%s}"
      curl "${CURL_OPTS[@]}" -s -X GET -H @"$AUTH_FILE" -H "Accept: application/json" "${OPENHAB_URL}/rest/items?recursive=false" | jq -r --arg d "$filter" \
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
  thing-status <uid>        Get Thing online status

Environment:
  OPENHAB_URL    openHAB URL (required)
  OPENHAB_TOKEN  Long-lived access token (required)

Examples:
  oa.sh on LivingRoom_Light
  oa.sh list Switch
EOF
    ;;
esac
