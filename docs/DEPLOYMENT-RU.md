# Развёртывание: пошаговая инструкция

## 1. Что нужно подготовить

Минимум:

- 1 зарубежный VPS: основной выход в зарубежный интернет.
- 1 российский VPS: опциональный RU endpoint, не основной приватный VPN.
- SSH-доступ к обоим серверам.
- Debian 12 или Ubuntu 22.04/24.04.

## 2. На зарубежном сервере

```bash
apt-get update && apt-get install -y git

git clone <your-private-repo-url> voodoo-vpn-stack
cd voodoo-vpn-stack
cp examples/node.env.example node.env
nano node.env
```

Пример `node.env`:

```bash
NODE_NAME="US-1"
NODE_ROLE="foreign"
SERVER_HOST="1.2.3.4"
REALITY_DEST="www.microsoft.com:443"
REALITY_SNI="www.microsoft.com"
CLIENT_NAME="serg-phone"
XRAY_PORT="443"
SSH_PORT="22"
BLOCK_BITTORRENT="yes"
LOG_LEVEL="warning"
```

Запуск:

```bash
sudo bash scripts/install_xray_reality_node.sh node.env
sudo bash scripts/show_xray_links.sh
```

Сохраните VLESS-ссылку и PNG QR-код.

## 3. На российском сервере

```bash
apt-get update && apt-get install -y git

git clone <your-private-repo-url> voodoo-vpn-stack
cd voodoo-vpn-stack
cp examples/node.env.example node-ru.env
nano node-ru.env
```

Пример:

```bash
NODE_NAME="RU-1"
NODE_ROLE="ru"
SERVER_HOST="5.6.7.8"
REALITY_DEST="www.yandex.ru:443"
REALITY_SNI="www.yandex.ru"
CLIENT_NAME="serg-phone"
XRAY_PORT="443"
SSH_PORT="22"
BLOCK_BITTORRENT="yes"
LOG_LEVEL="warning"
```

Запуск:

```bash
sudo bash scripts/install_xray_reality_node.sh node-ru.env
sudo bash scripts/show_xray_links.sh
```

## 4. Добавить членов семьи

На каждом сервере:

```bash
sudo bash scripts/add_xray_client.sh wife-phone
sudo bash scripts/add_xray_client.sh laptop-serg
sudo bash scripts/show_xray_links.sh
```

Лучше делать отдельный UUID на каждое устройство.

## 5. Бэкап

```bash
sudo bash scripts/backup_xray_node.sh
```

Бэкап появится в `/root/xray-node-backup-YYYYMMDD-HHMMSS.tar.gz`.
