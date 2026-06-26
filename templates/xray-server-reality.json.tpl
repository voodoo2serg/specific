{
  "log": {
    "loglevel": "__LOG_LEVEL__",
    "access": "none",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "tag": "vless-reality-in",
      "listen": "0.0.0.0",
      "port": __XRAY_PORT__,
      "protocol": "vless",
      "settings": {
        "clients": __CLIENTS_JSON__,
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "__REALITY_DEST__",
          "xver": 0,
          "serverNames": ["__REALITY_SNI__"],
          "privateKey": "__REALITY_PRIVATE_KEY__",
          "shortIds": ["__REALITY_SHORT_ID__"]
        }
      }
    }
  ],
  "outbounds": [
    {"tag": "direct", "protocol": "freedom"},
    {"tag": "block", "protocol": "freedom"}
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": __ROUTING_RULES_JSON__
  }
}
