#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="aro"
LOCAL_REDSOCKS_PORT="12345"
REDSOCKS_CONF="/etc/redsocks.conf"
REDSOCKS_SERVICE="/etc/systemd/system/redsocks.service"

echo "========================================"
echo "   SETUP ARO PROXY (redsocks + iptables)"
echo "========================================"
echo

if [[ "$EUID" -ne 0 ]]; then
  echo "Vui long chay bang root hoac sudo."
  exit 1
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  echo "Khong tim thay user '$TARGET_USER'."
  exit 1
fi

echo "Nhap thong tin proxy SOCKS5:"
read -rp "Proxy host: " PROXY_HOST
read -rp "Proxy port: " PROXY_PORT
read -rp "Proxy user: " PROXY_USER
read -rsp "Proxy pass: " PROXY_PASS
echo

if [[ -z "$PROXY_HOST" || -z "$PROXY_PORT" || -z "$PROXY_USER" || -z "$PROXY_PASS" ]]; then
  echo "Thieu thong tin proxy."
  exit 1
fi

if ! [[ "$PROXY_PORT" =~ ^[0-9]+$ ]]; then
  echo "Port khong hop le."
  exit 1
fi

echo ">>> Dang resolve host proxy..."
if [[ "$PROXY_HOST" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  PROXY_IP="$PROXY_HOST"
else
  PROXY_IP="$(getent ahostsv4 "$PROXY_HOST" | awk 'NR==1{print $1}')"
fi

if [[ -z "${PROXY_IP:-}" ]]; then
  echo "Khong resolve duoc host proxy: $PROXY_HOST"
  exit 1
fi

echo ">>> Proxy IP: $PROXY_IP"

export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y redsocks iptables-persistent curl

TARGET_UID="$(id -u "$TARGET_USER")"
echo ">>> UID user $TARGET_USER = $TARGET_UID"

cat > "$REDSOCKS_CONF" <<EOF2
base {
 log_debug = off;
 log_info = on;
 log = "file:/var/log/redsocks.log";
 daemon = off;
 redirector = iptables;
}

redsocks {
 local_ip = 127.0.0.1;
 local_port = $LOCAL_REDSOCKS_PORT;

 ip = $PROXY_IP;
 port = $PROXY_PORT;

 type = socks5;
 login = "$PROXY_USER";
 password = "$PROXY_PASS";
}
EOF2

cat > "$REDSOCKS_SERVICE" <<'EOF2'
[Unit]
Description=Redsocks transparent proxy redirector
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/sbin/redsocks -c /etc/redsocks.conf
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF2

pkill redsocks 2>/dev/null || true
sleep 1

iptables -t nat -D OUTPUT -p tcp -m owner --uid-owner "$TARGET_UID" -j REDSOCKS 2>/dev/null || true
iptables -t nat -F REDSOCKS 2>/dev/null || true
iptables -t nat -X REDSOCKS 2>/dev/null || true

iptables -t nat -N REDSOCKS
iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports "$LOCAL_REDSOCKS_PORT"
iptables -t nat -A OUTPUT -p tcp -m owner --uid-owner "$TARGET_UID" -j REDSOCKS

systemctl daemon-reload
systemctl enable redsocks
systemctl restart redsocks

mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo
echo ">>> Dang kiem tra..."
systemctl is-active redsocks
ss -tulpn | grep "$LOCAL_REDSOCKS_PORT" || true

echo
echo ">>> Test IP cua user $TARGET_USER:"
su - "$TARGET_USER" -c 'curl -s https://api.ipify.org ; echo'

echo
echo "XONG."
