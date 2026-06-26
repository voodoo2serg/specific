#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

TS="$(date +%Y%m%d-%H%M%S)"
OUT="/root/xray-node-backup-${TS}.tar.gz"
tar -czf "$OUT" /usr/local/etc/xray/config.json /etc/xray/voodoo 2>/dev/null
chmod 600 "$OUT"
echo "Backup created: $OUT"
