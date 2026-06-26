#!/usr/bin/env bash
set -euo pipefail

CLIENT_NAME="${1:-}"
if [ -z "$CLIENT_NAME" ]; then
  echo "Usage: sudo bash scripts/add_xray_client.sh <client-name>" >&2
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

if ! command -v xray >/dev/null 2>&1; then
  echo "xray command not found." >&2
  exit 1
fi

CONFIG="/usr/local/etc/xray/config.json"
CLIENTS="/etc/xray/voodoo/clients.json"

NEW_UUID="$(xray uuid)"
TMP="$(mktemp)"

jq --arg id "$NEW_UUID" --arg email "$CLIENT_NAME" \
  '.inbounds[0].settings.clients += [{id:$id,flow:"xtls-rprx-vision",email:$email}]' \
  "$CONFIG" > "$TMP"
install -m 600 "$TMP" "$CONFIG"
rm -f "$TMP"

TMP="$(mktemp)"
jq --arg name "$CLIENT_NAME" --arg uuid "$NEW_UUID" \
  '. += [{name:$name,uuid:$uuid}]' "$CLIENTS" > "$TMP"
install -m 600 "$TMP" "$CLIENTS"
rm -f "$TMP"

systemctl restart xray

echo "Added client: $CLIENT_NAME"
echo "UUID: $NEW_UUID"
echo "Run: sudo bash scripts/show_xray_links.sh"
