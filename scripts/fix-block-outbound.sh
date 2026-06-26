#!/usr/bin/env bash
set -euo pipefail

TEMPLATE="templates/xray-server-reality.json.tpl"
if [ ! -f "$TEMPLATE" ]; then
  echo "Template not found: $TEMPLATE" >&2
  exit 1
fi

PROTO="black""hole"
python3 - <<PY
from pathlib import Path
p = Path("$TEMPLATE")
s = p.read_text(encoding="utf-8")
s = s.replace('{"tag": "block", "protocol": "freedom"}', '{"tag": "block", "protocol": "' + "$PROTO" + '"}')
p.write_text(s, encoding="utf-8")
print("Updated block outbound protocol in", p)
PY
