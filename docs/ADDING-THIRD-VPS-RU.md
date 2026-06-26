# Добавление третьего VPS

Третий VPS нужен как аварийный резерв или как отдельный регион.

## Принцип

Не клонируйте полностью тот же профиль:

- другой провайдер;
- другая страна;
- другой camouflage target;
- отдельные UUID;
- отдельное имя узла, например `EU-2` или `SG-1`.

## Развёртывание

```bash
git clone <your-private-repo-url> voodoo-vpn-stack
cd voodoo-vpn-stack
cp examples/node.env.example node-third.env
nano node-third.env
sudo bash scripts/install_xray_reality_node.sh node-third.env
sudo bash scripts/show_xray_links.sh
```

Пример:

```bash
NODE_NAME="SG-1"
NODE_ROLE="foreign"
SERVER_HOST="9.9.9.9"
REALITY_DEST="www.cloudflare.com:443"
REALITY_SNI="www.cloudflare.com"
CLIENT_NAME="serg-phone"
```

После этого добавьте новый VLESS link в клиент как `Emergency` или `Backup`.
