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
    echo ">>> Dang cai ARO theo tung buoc..."

    # B1: Update he thong
    sudo apt update && sudo apt upgrade -y

    # B2: Cai XFCE
    sudo apt install xfce4 xfce4-goodies -y

    # B3: Cai thu vien can thiet
    sudo apt install dbus-x11 x11-xserver-utils -y

    # B4: Cai XRDP
    sudo apt install xrdp -y

    # B5: Set XFCE lam mac dinh
    echo "startxfce4" > ~/.xsession
    chmod 644 ~/.xsession

    # B6: Bat XRDP
    sudo systemctl enable xrdp
    sudo systemctl start xrdp

    # B7: Tai ARO Desktop
    wget https://download.aro.network/files/packages/linux/ARO_Desktop_latest_debian.deb || {
        echo "Download ARO that bai!"
        return
    }

    # B8: Cai ARO
    sudo apt install ./ARO_Desktop_latest_debian.deb -y || {
        echo "Cai dat ARO that bai!"
        return
    }

    # Restart XRDP
    sudo systemctl restart xrdp

    echo ">>> DONE!"
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

    if [ -f /swapfile ]; then
        echo "Swap da ton tai!"
        return
    fi

    sudo fallocate -l ${size}G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile

    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null

    free -h
}

# ================= OPTION 3 =================
auto_xrdp() {
    echo ">>> Dang setup XRDP auto..."

    sudo systemctl enable xrdp
    sudo systemctl enable dbus

    echo "startxfce4" > /root/.xsession
    sudo chmod 644 /root/.xsession

    sudo systemctl restart xrdp

    echo ">>> XRDP auto OK"
}

# ================= OPTION 4 =================
create_user() {
    read -p "Nhap username: " user
    read -s -p "Nhap password: " pass
    echo ""

    if id "$user" >/dev/null 2>&1; then
        echo "User da ton tai!"
        return
    fi

    sudo useradd -m -s /bin/bash "$user"
    echo "$user:$pass" | sudo chpasswd

    sudo usermod -aG sudo "$user"

    echo "startxfce4" | sudo tee /home/$user/.xsession >/dev/null
    sudo chmod 644 /home/$user/.xsession
    sudo chown $user:$user /home/$user/.xsession

    echo "User: $user | Pass: $pass" | sudo tee -a /root/user_info.txt >/dev/null

    echo ">>> Tao user thanh cong!"
    echo ">>> Thong tin da luu tai /root/user_info.txt"
}

# ================= OPTION 5 =================
fix_xrdp() {
    echo ">>> Dang fix XRDP..."

    echo "startxfce4" > ~/.xsession
    chmod 644 ~/.xsession

    sudo systemctl restart dbus
    sudo systemctl restart xrdp

    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml

    cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
EOF

    echo ">>> Fix xong! Neu van loi, reboot VPS"
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
