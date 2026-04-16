#!/bin/bash

clear
echo "==========================================================="
echo "        aro thuyktutt github (auto setup VPS)"
echo "==========================================================="
echo ""
echo "1) Cai dat ARO Desktop + XRDP"
echo "2) Tao SWAP RAM (1-4GB)"
echo "3) Auto XRDP sau reboot (khong can login)"
echo "4) Tao user + password (luu lai)"
echo "5) Fix loi XRDP (man hinh den, lag)"
echo "0) Thoat"
echo ""

read -p "Chon option: " choice

# ================= OPTION 1 =================

install_aro() {
echo ">>> Dang cai ARO..."

```
apt update && apt upgrade -y

apt install xfce4 xfce4-goodies -y
apt install dbus-x11 x11-xserver-utils -y
apt install xrdp -y

echo "startxfce4" > ~/.xsession
chmod 644 ~/.xsession

systemctl enable xrdp
systemctl start xrdp

wget -O aro.deb https://download.aro.network/files/packages/linux/ARO_Desktop_latest_debian.deb || {
    echo "Download ARO that bai!"
    return
}

apt install ./aro.deb -y

systemctl restart xrdp

echo ">>> DONE!"
```

}

# ================= OPTION 2 =================

swap_ram() {
echo "Chon dung luong swap:"
echo "1) 1GB"
echo "2) 2GB"
echo "3) 3GB"
echo "4) 4GB"
read -p "Lua chon: " s

```
case $s in
    1) size=1 ;;
    2) size=2 ;;
    3) size=3 ;;
    4) size=4 ;;
    *) echo "Sai lua chon"; return ;;
esac

if [ -f /swapfile ]; then
    echo "Swap da ton tai!"
    return
fi

fallocate -l ${size}G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo '/swapfile none swap sw 0 0' >> /etc/fstab

free -h
```

}

# ================= OPTION 3 =================

auto_xrdp() {
systemctl enable xrdp
systemctl enable dbus

```
echo "startxfce4" > /root/.xsession

systemctl restart xrdp

echo ">>> XRDP auto OK"
```

}

# ================= OPTION 4 =================

create_user() {
read -p "Nhap username: " user
read -p "Nhap password: " pass

```
useradd -m $user
echo "$user:$pass" | chpasswd

usermod -aG sudo $user

echo "startxfce4" > /home/$user/.xsession
chown $user:$user /home/$user/.xsession

echo "User: $user | Pass: $pass" >> /root/user_info.txt

echo ">>> Tao user thanh cong!"
```

}

# ================= OPTION 5 =================

fix_xrdp() {
echo ">>> Dang fix XRDP..."

```
# fix man hinh den
echo "startxfce4" > /root/.xsession
chmod 644 /root/.xsession

# fix dbus
systemctl restart dbus

# fix xrdp
systemctl restart xrdp

# tat hieu ung XFCE (giam lag)
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml

cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<EOF
```

<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
EOF

```
echo ">>> Fix xong! Neu van loi, reboot VPS"
```

}

# ================= RUN =================

case $choice in
1) install_aro ;;
2) swap_ram ;;
3) auto_xrdp ;;
4) create_user ;;
5) fix_xrdp ;;
0) exit ;;
*) echo "Lua chon khong hop le!" ;;
esac
