#!/bin/bash

clear
echo "==========================================================="
echo "        aro thuyktutt github (auto setup VPS)"
echo "==========================================================="
echo ""
echo "1) Cai dat ARO Desktop + XRDP"
echo "2) Tao SWAP RAM (1-4GB) + toi uu"
echo "3) Auto XRDP sau reboot"
echo "4) Tao user + password (luu lai)"
echo "5) Fix loi XRDP (man hinh den, lag, dis)"
echo "6) Xoa sach ARO + XRDP + file rac"
echo "7) Xoa user da tao"
echo "0) Thoat"
echo ""

read -p "Chon option: " choice

# ================= OPTION 1 =================
install_aro() {
    echo ">>> Dang cai ARO Desktop + XRDP..."

    # B1: Update he thong
    apt update && apt upgrade -y

    # B2: Cai XFCE
    apt install xfce4 xfce4-goodies -y

    # B3: Cai thu vien can thiet
    apt install dbus-x11 x11-xserver-utils -y

    # B4: Cai XRDP
    apt install xrdp xorgxrdp -y

    # B5: Set XFCE lam mac dinh
    echo "startxfce4" > /root/.xsession
    chmod 644 /root/.xsession

    # B6: Bat XRDP
    systemctl enable xrdp
    systemctl start xrdp

    # B7: Tai ARO Desktop
    wget -O ARO_Desktop_latest_debian.deb https://download.aro.network/files/packages/linux/ARO_Desktop_latest_debian.deb || {
        echo ">>> Download ARO that bai!"
        return
    }

    # B8: Cai ARO
    apt install ./ARO_Desktop_latest_debian.deb -y || {
        echo ">>> Cai dat ARO that bai!"
        return
    }

    # Restart XRDP
    systemctl restart xrdp

    echo ">>> Cai dat xong!"
    echo ">>> Neu muon dang nhap XRDP on dinh, hay chon option 4 de tao user rieng"
}

# ================= OPTION 2 =================
swap_ram() {
    echo "Chon dung luong swap:"
    echo "1) 1GB"
    echo "2) 2GB"
    echo "3) 3GB"
    echo "4) 4GB"
    read -p "Lua chon: " s

    case $s in
        1) size=1 ;;
        2) size=2 ;;
        3) size=3 ;;
        4) size=4 ;;
        *) echo "Sai lua chon"; return ;;
    esac

    echo ">>> Dang tao swap ${size}G..."

    # Xoa swap cu neu co
    if [ -f /swapfile ]; then
        swapoff /swapfile 2>/dev/null
        rm -f /swapfile
        sed -i '\|/swapfile none swap sw 0 0|d' /etc/fstab
    fi

    # B1: Tao swap
    fallocate -l ${size}G /swapfile

    # B2: Set quyen
    chmod 600 /swapfile

    # B3: Tao swap
    mkswap /swapfile

    # B4: Bat swap
    swapon /swapfile

    # B5: Kiem tra swap
    swapon --show

    # B6: Kiem tra RAM
    free -h
    df -h

    # B7: Auto khi reboot
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab >/dev/null

    # B8: Check lai
    cat /etc/fstab

    # B9: Toi uu swap
    sysctl vm.swappiness=10

    # B10: Luu config
    sed -i '/^vm.swappiness=/d' /etc/sysctl.conf
    echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf >/dev/null

    # B11: Toi uu cache
    sed -i '/^vm.vfs_cache_pressure=/d' /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf >/dev/null

    # B12: Ap dung
    sysctl -p

    echo ">>> Tao va toi uu swap xong!"
}

# ================= OPTION 3 =================
auto_xrdp() {
    echo ">>> Dang setup XRDP auto..."

    systemctl enable xrdp
    systemctl enable dbus

    echo "startxfce4" > /root/.xsession
    chmod 644 /root/.xsession

    systemctl restart xrdp

    echo ">>> XRDP auto OK"
}

# ================= OPTION 4 =================
create_user() {
    read -p "Nhap username: " user
    read -s -p "Nhap password: " pass
    echo ""

    if id "$user" >/dev/null 2>&1; then
        echo ">>> User da ton tai!"
        return
    fi

    adduser --disabled-password --gecos "" "$user"
    echo "$user:$pass" | chpasswd
    usermod -aG sudo "$user"

    echo "startxfce4" > /home/$user/.xsession
    chmod 644 /home/$user/.xsession
    chown $user:$user /home/$user/.xsession

    echo "User: $user | Pass: $pass" >> /root/user_info.txt

    systemctl restart xrdp

    echo ">>> Tao user thanh cong!"
    echo ">>> Thong tin da luu tai /root/user_info.txt"
    echo ">>> Dang nhap XRDP bang user: $user"
}

# ================= OPTION 5 =================
fix_xrdp() {
    echo ">>> Dang fix XRDP..."

    echo "startxfce4" > /root/.xsession
    chmod 644 /root/.xsession

    mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml
    cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
EOF

    cp /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.bak 2>/dev/null

    cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
if [ -r /etc/profile ]; then
    . /etc/profile
fi
if [ -r ~/.profile ]; then
    . ~/.profile
fi
exec startxfce4
EOF

    chmod +x /etc/xrdp/startwm.sh

    systemctl restart dbus
    systemctl restart xrdp

    echo ">>> Fix xong! Neu van loi, reboot VPS"
}

# ================= OPTION 6 =================
remove_all() {
    echo ">>> Dang xoa sach ARO + XRDP + file rac..."

    systemctl stop xrdp 2>/dev/null

    apt remove --purge xrdp xorgxrdp -y 2>/dev/null
    apt remove --purge aro-desktop -y 2>/dev/null
    apt autoremove --purge -y
    apt autoclean -y

    rm -f /root/.xsession
    rm -f /root/aro.deb
    rm -f /root/ARO_Desktop_latest_debian.deb
    rm -f /etc/xrdp/startwm.sh.bak
    rm -rf /root/.config/xfce4/xfconf/xfce-perchannel-xml

    echo ">>> Da xoa xong ARO + XRDP + file rac"
}

# ================= OPTION 7 =================
remove_user() {
    read -p "Nhap username can xoa: " user

    if ! id "$user" >/dev/null 2>&1; then
        echo ">>> User khong ton tai!"
        return
    fi

    pkill -u "$user" 2>/dev/null
    userdel -r "$user"

    sed -i "/User: $user | Pass:/d" /root/user_info.txt 2>/dev/null

    echo ">>> Da xoa user: $user"
}

# ================= RUN =================
case $choice in
    1) install_aro ;;
    2) swap_ram ;;
    3) auto_xrdp ;;
    4) create_user ;;
    5) fix_xrdp ;;
    6) remove_all ;;
    7) remove_user ;;
    0) exit ;;
    *) echo "Lua chon khong hop le!" ;;
esac
