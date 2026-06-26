#!/usr/bin/env bash
set -euo pipefail

NODE_META="/etc/xray/voodoo/node.env"
CLIENTS="/etc/xray/voodoo/clients.json"
OUT_DIR="/root/xray-client-links"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

if [ ! -f "$NODE_META" ] || [ ! -f "$CLIENTS" ]; then
  echo "Node metadata not found. Install the node first." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$NODE_META"
mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR"

COUNT="$(jq length "$CLIENTS")"
I=0
while [ "$I" -lt "$COUNT" ]; do
  NAME="$(jq -r ".[$I].name" "$CLIENTS")"
  UUID="$(jq -r ".[$I].uuid" "$CLIENTS")"
  TAG="${NODE_NAME}-${NAME}"
  ENC_TAG="$(python3 - <<PY
from urllib.parse import quote
print(quote('$TAG'))
PY
)"
  LINK="vless://${UUID}@${SERVER_HOST}:${XRAY_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}&type=tcp&headerType=none#${ENC_TAG}"

  echo
  echo "=== $TAG ==="
  echo "$LINK"
  printf '%s' "$LINK" > "$OUT_DIR/${TAG}.txt"
  if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ANSIUTF8 "$LINK" || true
    qrencode -o "$OUT_DIR/${TAG}.png" "$LINK" || true
    echo "PNG QR: $OUT_DIR/${TAG}.png"
  else
    echo "qrencode is not installed. Install it to print QR codes."
  fi
  I=$((I + 1))
done
