# Voodoo VPN Stack

Reproducible self-hosted access stack for two practical modes:

1. **Full Foreign** - all traffic goes through a foreign VPS.
2. **RU Compatible** - Russian government/banking/local services go direct, foreign traffic goes through a foreign VPS. Optional RU VPS can be added as a separate endpoint for selected routes.

This repository does **not** promise unblockability. It gives you a controlled baseline: Xray-core + VLESS + REALITY + XTLS-Vision on servers, plus sing-box client config generation and operational scripts.

## Supported server OS

- Debian 12
- Ubuntu 22.04 / 24.04

Run server scripts as root or with sudo.

## Repository layout

```text
scripts/install_xray_reality_node.sh    # Install one Xray REALITY node
scripts/install-hardening.sh            # SSH/firewall/fail2ban hardening
scripts/add_xray_client.sh              # Add another UUID/client
scripts/revoke-client.sh                # Revoke one client by name or UUID
scripts/show_xray_links.sh              # Print VLESS links and QR codes
scripts/backup_xray_node.sh             # Backup node config
scripts/health-check.sh                 # Check service/config/port/target reachability
scripts/generate-sing-box-config.py     # Generate sing-box client JSON from VLESS links
scripts/check-reality-targets.sh        # Check REALITY_DEST candidates from a VPS

client/sing-box-ru-compatible.template.json
client/sing-box-full-foreign.template.json
templates/xray-server-reality.json.tpl
examples/node.env.example

docs/DEPLOYMENT-RU.md
docs/ROUTING-RU.md
docs/CLIENT-PROFILES-RU.md
docs/ADDING-THIRD-VPS-RU.md
docs/REALITY-TARGETS-RU.md
SECURITY.md
```

## Quick start: foreign server

On the US/EU/Asia VPS:

```bash
apt-get update && apt-get install -y git unzip

git clone https://github.com/voodoo2serg/specific.git voodoo-vpn-stack
cd voodoo-vpn-stack
cp examples/node.env.example node.env
nano node.env
```

Set in `node.env`:

```bash
NODE_NAME="US-1"
NODE_ROLE="foreign"
SERVER_HOST="YOUR_PUBLIC_IP_OR_DOMAIN"
REALITY_DEST="www.microsoft.com:443"
REALITY_SNI="www.microsoft.com"
CLIENT_NAME="serg-phone"
XRAY_PORT="443"
SSH_PORT="22"
```

Install:

```bash
sudo bash scripts/install_xray_reality_node.sh node.env
sudo bash scripts/show_xray_links.sh
sudo bash scripts/health-check.sh
```

## Quick start: Russian server

On the RU VPS:

```bash
git clone https://github.com/voodoo2serg/specific.git voodoo-vpn-stack
cd voodoo-vpn-stack
cp examples/node.env.example node-ru.env
nano node-ru.env
```

Set:

```bash
NODE_NAME="RU-1"
NODE_ROLE="ru"
SERVER_HOST="YOUR_RU_PUBLIC_IP_OR_DOMAIN"
REALITY_DEST="www.yandex.ru:443"
REALITY_SNI="www.yandex.ru"
CLIENT_NAME="serg-phone"
```

Install:

```bash
sudo bash scripts/install_xray_reality_node.sh node-ru.env
sudo bash scripts/show_xray_links.sh
sudo bash scripts/health-check.sh
```

Note: RU VPS is not recommended as your main privacy endpoint. Use it only as an optional route for selected Russian services. For government services and banks, `direct` is often more reliable than RU VPS.

## SSH hardening

Recommended after you have confirmed basic SSH access.

Edit `node.env`:

```bash
HARDENING_USER="serg"
HARDENING_PUBLIC_KEY="ssh-ed25519 AAAA... your-key-comment"
DISABLE_PASSWORD_AUTH="yes"
DISABLE_ROOT_LOGIN="no"
ENABLE_UFW="yes"
INSTALL_FAIL2BAN="yes"
```

Run:

```bash
sudo bash scripts/install-hardening.sh node.env
```

After confirming login as the sudo user, you may set:

```bash
DISABLE_ROOT_LOGIN="yes"
```

Then run hardening again. Do not close your current SSH session until a second session works.

## Add and revoke clients

Add a separate client per person/device:

```bash
sudo bash scripts/add_xray_client.sh wife-phone
sudo bash scripts/add_xray_client.sh serg-laptop
sudo bash scripts/show_xray_links.sh
```

Revoke by name or UUID:

```bash
sudo bash scripts/revoke-client.sh wife-phone
sudo bash scripts/revoke-client.sh 00000000-0000-0000-0000-000000000000
```

## QR codes

After installation or adding clients:

```bash
sudo bash scripts/show_xray_links.sh
```

The script prints:

- VLESS share links
- terminal QR codes, if `qrencode` is installed
- PNG QR codes in `/root/xray-client-links/`

## Generate sing-box client configs

Full Foreign:

```bash
python3 scripts/generate-sing-box-config.py \
  --mode full-foreign \
  --foreign-link 'vless://PASTE_FOREIGN_LINK_HERE' \
  --output serg-full-foreign.json
```

RU Compatible:

```bash
python3 scripts/generate-sing-box-config.py \
  --mode ru-compatible \
  --foreign-link 'vless://PASTE_FOREIGN_LINK_HERE' \
  --output serg-ru-compatible.json
```

RU Compatible with optional RU node stored in config:

```bash
python3 scripts/generate-sing-box-config.py \
  --mode ru-compatible \
  --foreign-link 'vless://PASTE_FOREIGN_LINK_HERE' \
  --ru-link 'vless://PASTE_RU_LINK_HERE' \
  --output serg-ru-compatible-with-ru-node.json
```

See `docs/CLIENT-PROFILES-RU.md` for Android/iOS/Windows guidance.

## Check REALITY_DEST candidates per region

Run on each VPS, not from your laptop:

```bash
bash scripts/check-reality-targets.sh us
bash scripts/check-reality-targets.sh eu
bash scripts/check-reality-targets.sh asia
bash scripts/check-reality-targets.sh ru
```

Use a candidate marked `good`:

```bash
REALITY_SNI="host"
REALITY_DEST="host:443"
```

See `docs/REALITY-TARGETS-RU.md`.

## Client modes

### Full Foreign

All traffic goes to the foreign VPS.

### RU Compatible

Core logic:

```text
private/local networks -> direct
Russian government/banks/local domains -> direct
.ru / .рф -> direct
foreign internet -> foreign VPS
optional selected RU domains -> RU VPS
```

### Emergency

Same as Full Foreign, but using another VPS, ideally another provider, region, and ASN.

## Security notes

- Use SSH keys, not passwords.
- Disable root SSH login only after sudo-user key login works.
- Keep one UUID per person/device.
- Revoke lost devices immediately.
- Keep generated links private.
- Do not expose Xray API/admin ports to the internet.
- Do not assume any protocol is permanently unblockable.

## Домены-исключения для RU Compatible

Настраиваемый список доменов, которые идут напрямую, лежит в:

```bash
rules/ru-direct-domains.txt
```

По умолчанию туда уже добавлены Госуслуги, налоговая, mos.ru, основные банки, Ozon/Wildberries, Яндекс/VK/Mail.ru и другие российские сервисы.

При генерации sing-box-конфига список подключается так:

```bash
python3 scripts/generate-sing-box-config.py \
  --mode ru-compatible \
  --foreign-link 'vless://...' \
  --ru-direct-domains-file rules/ru-direct-domains.txt \
  --output serg-ru-compatible.json
```

Подробнее: `docs/DOMAIN-EXCEPTIONS-RU.md`.
