#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-}"
if [ -n "$ENV_FILE" ]; then
  if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file not found: $ENV_FILE" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash scripts/install-hardening.sh [node.env]" >&2
  exit 1
fi

SSH_PORT="${SSH_PORT:-22}"
HARDENING_USER="${HARDENING_USER:-}"
HARDENING_PUBLIC_KEY="${HARDENING_PUBLIC_KEY:-}"
DISABLE_PASSWORD_AUTH="${DISABLE_PASSWORD_AUTH:-yes}"
DISABLE_ROOT_LOGIN="${DISABLE_ROOT_LOGIN:-no}"
ENABLE_UFW="${ENABLE_UFW:-yes}"
INSTALL_FAIL2BAN="${INSTALL_FAIL2BAN:-yes}"
XRAY_PORT="${XRAY_PORT:-443}"

backup_file() {
  local f="$1"
  if [ -f "$f" ]; then
    cp -a "$f" "${f}.bak.$(date +%Y%m%d-%H%M%S)"
  fi
}

apt-get update
apt-get install -y sudo openssh-server ufw ca-certificates curl
if [ "$INSTALL_FAIL2BAN" = "yes" ]; then
  apt-get install -y fail2ban
fi

if [ -n "$HARDENING_USER" ]; then
  if ! id "$HARDENING_USER" >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" "$HARDENING_USER"
    usermod -aG sudo "$HARDENING_USER"
  fi
  mkdir -p "/home/$HARDENING_USER/.ssh"
  chmod 700 "/home/$HARDENING_USER/.ssh"
  if [ -n "$HARDENING_PUBLIC_KEY" ]; then
    printf '%s\n' "$HARDENING_PUBLIC_KEY" >> "/home/$HARDENING_USER/.ssh/authorized_keys"
  elif [ -f /root/.ssh/authorized_keys ]; then
    cat /root/.ssh/authorized_keys >> "/home/$HARDENING_USER/.ssh/authorized_keys"
  fi
  sort -u "/home/$HARDENING_USER/.ssh/authorized_keys" -o "/home/$HARDENING_USER/.ssh/authorized_keys" || true
  chmod 600 "/home/$HARDENING_USER/.ssh/authorized_keys"
  chown -R "$HARDENING_USER:$HARDENING_USER" "/home/$HARDENING_USER/.ssh"
fi

SSHD_DIR="/etc/ssh/sshd_config.d"
mkdir -p "$SSHD_DIR"
backup_file /etc/ssh/sshd_config
cat > "$SSHD_DIR/99-voodoo-hardening.conf" <<CONF
Port $SSH_PORT
PubkeyAuthentication yes
KbdInteractiveAuthentication no
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
LoginGraceTime 30
CONF

if [ "$DISABLE_PASSWORD_AUTH" = "yes" ]; then
  cat >> "$SSHD_DIR/99-voodoo-hardening.conf" <<CONF
PasswordAuthentication no
PermitEmptyPasswords no
CONF
fi

if [ "$DISABLE_ROOT_LOGIN" = "yes" ]; then
  if [ -z "$HARDENING_USER" ]; then
    echo "Refusing to disable root login without HARDENING_USER." >&2
    exit 1
  fi
  if [ ! -s "/home/$HARDENING_USER/.ssh/authorized_keys" ]; then
    echo "Refusing to disable root login: $HARDENING_USER has no authorized_keys." >&2
    exit 1
  fi
  echo "PermitRootLogin no" >> "$SSHD_DIR/99-voodoo-hardening.conf"
else
  echo "PermitRootLogin prohibit-password" >> "$SSHD_DIR/99-voodoo-hardening.conf"
fi

sshd -t
systemctl restart ssh || systemctl restart sshd

if [ "$INSTALL_FAIL2BAN" = "yes" ]; then
  cat > /etc/fail2ban/jail.d/voodoo-sshd.conf <<CONF
[sshd]
enabled = true
port = $SSH_PORT
maxretry = 4
findtime = 10m
bantime = 1h
CONF
  systemctl enable fail2ban
  systemctl restart fail2ban
fi

if [ "$ENABLE_UFW" = "yes" ]; then
  ufw allow "${SSH_PORT}/tcp"
  ufw allow "${XRAY_PORT}/tcp"
  ufw --force enable
fi

echo "SSH hardening applied. Open a second SSH session and verify access before closing the current one."
