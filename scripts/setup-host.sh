#!/usr/bin/env bash
# Run once on the Ubuntu victim VM:  sudo ./scripts/setup-host.sh
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT_DIR=/opt/victim-lab

[ "$EUID" -eq 0 ] || { echo "run as root"; exit 1; }

echo "[1/6] Packages"
apt-get update
apt-get install -y ca-certificates curl git openssl chrony logrotate openssh-server
command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh

echo "[2/6] Swap (2GB RAM VM)"
if ! swapon --show | grep -q swapfile; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "[3/6] Project dir + log dirs"
if [ "$(pwd)" != "$PROJECT_DIR" ]; then
  mkdir -p "$PROJECT_DIR" && cp -a . "$PROJECT_DIR"/ && cd "$PROJECT_DIR"
fi
mkdir -p logs/nginx logs/modsecurity logs/docker
chmod -R 777 logs      # nginx container runs as non-root; lab only
[ -f .env ] || cp .env.example .env

echo "[4/6] Self-signed cert"
if [ ! -f nginx/certs/server.crt ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout nginx/certs/server.key -out nginx/certs/server.crt \
    -subj "/CN=*.lab" -addext "subjectAltName=DNS:dvwa.lab,DNS:juice.lab"
  chmod 644 nginx/certs/server.key
fi

echo "[5/6] Logrotate"
cp config/logrotate-victim-lab /etc/logrotate.d/victim-lab

echo "[6/6] Splunk UF configs (if installed)"
if [ -d /opt/splunkforwarder ]; then
  cp splunk-uf/inputs.conf splunk-uf/outputs.conf /opt/splunkforwarder/etc/system/local/
  /opt/splunkforwarder/bin/splunk restart
else
  echo "Splunk UF not installed yet. Install the .deb, then re-run this script."
fi

echo "Done. Next: cd $PROJECT_DIR && docker compose up -d"
