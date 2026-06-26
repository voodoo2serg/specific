#!/usr/bin/env bash
set -euo pipefail

NODE_META="/etc/xray/voodoo/node.env"
CONFIG="/usr/local/etc/xray/config.json"
STATUS=0

say_ok(){ echo "OK   $*"; }
say_bad(){ echo "FAIL $*"; STATUS=1; }
say_warn(){ echo "WARN $*"; }

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

if [ -f "$NODE_META" ]; then
  # shellcheck disable=SC1090
  source "$NODE_META"
else
  say_bad "node metadata missing: $NODE_META"
fi

if command -v xray >/dev/null 2>&1; then
  say_ok "xray binary found: $(xray version | head -n1)"
else
  say_bad "xray binary not found"
fi

if [ -f "$CONFIG" ]; then
  if xray run -test -config "$CONFIG" >/tmp/voodoo-xray-test.log 2>&1; then
    say_ok "xray config test passed"
  else
    say_bad "xray config test failed"
    cat /tmp/voodoo-xray-test.log
  fi
else
  say_bad "config missing: $CONFIG"
fi

if systemctl is-active --quiet xray; then
  say_ok "xray service is active"
else
  say_bad "xray service is not active"
  systemctl --no-pager status xray || true
fi

PORT="${XRAY_PORT:-443}"
if ss -lnt | awk '{print $4}' | grep -Eq "(:|\.)${PORT}$"; then
  say_ok "port $PORT is listening"
else
  say_bad "port $PORT is not listening"
fi

if [ -n "${REALITY_SNI:-}" ]; then
  if timeout 8 bash -c "</dev/tcp/${REALITY_SNI}/443" >/dev/null 2>&1; then
    say_ok "REALITY SNI reachable from this VPS: $REALITY_SNI:443"
  else
    say_warn "cannot connect from this VPS to REALITY SNI: $REALITY_SNI:443"
  fi
fi

if command -v ufw >/dev/null 2>&1; then
  ufw status verbose || true
fi

if [ -f /var/log/xray/error.log ]; then
  echo "--- last xray error log lines ---"
  tail -n 30 /var/log/xray/error.log || true
fi

exit "$STATUS"
