#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: sudo bash scripts/revoke-client.sh <client-name-or-uuid>" >&2
  exit 1
fi
if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi
CONFIG="/usr/local/etc/xray/config.json"
CLIENTS="/etc/xray/voodoo/clients.json"
if [ ! -f "$CONFIG" ] || [ ! -f "$CLIENTS" ]; then
  echo "Xray config or clients database not found." >&2
  exit 1
fi

UUID_TO_REMOVE="$TARGET"
if jq -e --arg t "$TARGET" '.[] | select(.name==$t)' "$CLIENTS" >/dev/null; then
  UUID_TO_REMOVE="$(jq -r --arg t "$TARGET" '.[] | select(.name==$t) | .uuid' "$CLIENTS" | head -n1)"
fi

if ! jq -e --arg u "$UUID_TO_REMOVE" '.inbounds[0].settings.clients[]? | select(.id==$u)' "$CONFIG" >/dev/null; then
  echo "Client not found in Xray config: $TARGET" >&2
  exit 1
fi

TS="$(date +%Y%m%d-%H%M%S)"
cp -a "$CONFIG" "${CONFIG}.bak.${TS}"
cp -a "$CLIENTS" "${CLIENTS}.bak.${TS}"

TMP="$(mktemp)"
jq --arg u "$UUID_TO_REMOVE" '.inbounds[0].settings.clients |= map(select(.id != $u))' "$CONFIG" > "$TMP"
install -m 600 "$TMP" "$CONFIG"
rm -f "$TMP"

TMP="$(mktemp)"
jq --arg u "$UUID_TO_REMOVE" '. |= map(select(.uuid != $u))' "$CLIENTS" > "$TMP"
install -m 600 "$TMP" "$CLIENTS"
rm -f "$TMP"

xray run -test -config "$CONFIG"
systemctl restart xray
rm -f "/root/xray-client-links/"*"${TARGET}"* 2>/dev/null || true

echo "Revoked client: $TARGET"
echo "Removed UUID: $UUID_TO_REMOVE"
