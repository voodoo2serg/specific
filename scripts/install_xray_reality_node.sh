#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-node.env}"
if [ ! -f "$ENV_FILE" ]; then
  echo "Environment file not found: $ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

NODE_NAME="${NODE_NAME:-node}"
NODE_ROLE="${NODE_ROLE:-foreign}"
SERVER_HOST="${SERVER_HOST:-}"
REALITY_DEST="${REALITY_DEST:-www.microsoft.com:443}"
REALITY_SNI="${REALITY_SNI:-www.microsoft.com}"
CLIENT_NAME="${CLIENT_NAME:-client-1}"
XRAY_PORT="${XRAY_PORT:-443}"
SSH_PORT="${SSH_PORT:-22}"
BLOCK_BITTORRENT="${BLOCK_BITTORRENT:-yes}"
LOG_LEVEL="${LOG_LEVEL:-warning}"

if [ -z "$SERVER_HOST" ] || [ "$SERVER_HOST" = "CHANGE_ME_PUBLIC_IP_OR_DOMAIN" ]; then
  echo "Set SERVER_HOST in $ENV_FILE first." >&2
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash $0 $ENV_FILE" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl ca-certificates
fi

apt-get update
apt-get install -y curl ca-certificates unzip jq qrencode openssl ufw python3

if ! command -v xray >/dev/null 2>&1; then
  echo "Installing Xray using the official XTLS installer..."
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi

mkdir -p /etc/xray/voodoo /root/xray-client-links /var/log/xray
chmod 700 /etc/xray/voodoo /root/xray-client-links

CLIENT_UUID="$(xray uuid)"
KEY_PAIR="$(xray x25519)"
PRIVATE_KEY="$(printf '%s\n' "$KEY_PAIR" | awk '/Private key:/ {print $3}')"
PUBLIC_KEY="$(printf '%s\n' "$KEY_PAIR" | awk '/Public key:/ {print $3}')"
SHORT_ID="$(openssl rand -hex 8)"

CLIENTS_JSON="$(jq -n --arg id "$CLIENT_UUID" --arg email "$CLIENT_NAME" '[{id:$id,flow:"xtls-rprx-vision",email:$email}]')"

if [ "$BLOCK_BITTORRENT" = "yes" ]; then
  ROUTING_RULES_JSON='[
    {"type":"field","protocol":["bittorrent"],"outboundTag":"block"}
  ]'
else
  ROUTING_RULES_JSON='[]'
fi

sed \
  -e "s|__LOG_LEVEL__|$LOG_LEVEL|g" \
  -e "s|__XRAY_PORT__|$XRAY_PORT|g" \
  -e "s|__CLIENTS_JSON__|$CLIENTS_JSON|g" \
  -e "s|__REALITY_DEST__|$REALITY_DEST|g" \
  -e "s|__REALITY_SNI__|$REALITY_SNI|g" \
  -e "s|__REALITY_PRIVATE_KEY__|$PRIVATE_KEY|g" \
  -e "s|__REALITY_SHORT_ID__|$SHORT_ID|g" \
  -e "s|__ROUTING_RULES_JSON__|$ROUTING_RULES_JSON|g" \
  templates/xray-server-reality.json.tpl > /usr/local/etc/xray/config.json

cat > /etc/xray/voodoo/node.env <<META
NODE_NAME="$NODE_NAME"
NODE_ROLE="$NODE_ROLE"
SERVER_HOST="$SERVER_HOST"
XRAY_PORT="$XRAY_PORT"
REALITY_DEST="$REALITY_DEST"
REALITY_SNI="$REALITY_SNI"
REALITY_PUBLIC_KEY="$PUBLIC_KEY"
REALITY_SHORT_ID="$SHORT_ID"
META

jq -n --arg name "$CLIENT_NAME" --arg uuid "$CLIENT_UUID" '[{name:$name,uuid:$uuid}]' > /etc/xray/voodoo/clients.json
chmod 600 /etc/xray/voodoo/node.env /etc/xray/voodoo/clients.json /usr/local/etc/xray/config.json

systemctl enable xray
systemctl restart xray

ufw allow "${SSH_PORT}/tcp" || true
ufw allow "${XRAY_PORT}/tcp" || true
ufw --force enable || true

echo "Installed node: $NODE_NAME ($NODE_ROLE)"
echo "Server: $SERVER_HOST:$XRAY_PORT"
echo "Initial client: $CLIENT_NAME"
echo "Run: sudo bash scripts/show_xray_links.sh"
