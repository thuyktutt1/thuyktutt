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
echo "8) Tao nhieu user ARO"
echo "0) Thoat"
echo ""

read -p "Chon option: " choice

# ================= OPTION 1 =================
install_aro() {
    echo ">>> Dang cai ARO Desktop + XRDP..."

    apt update && apt upgrade -y

    apt install xfce4 xfce4-goodies -y

    apt install dbus-x11 x11-xserver-utils -y

    apt install xrdp xorgxrdp -y

    echo "startxfce4" > /root/.xsession
    chmod 644 /root/.xsession

    systemctl enable xrdp
    systemctl start xrdp

    wget -O ARO_Desktop_latest_debian.deb https://download.aro.network/files/packages/linux/ARO_Desktop_latest_debian.deb || {
        echo ">>> Download ARO that bai!"
        return
    }

    apt install ./ARO_Desktop_latest_debian.deb -y || {
        echo ">>> Cai dat ARO that bai!"
        return
    }

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

    if [ -f /swapfile ]; then
        swapoff /swapfile 2>/dev/null
        rm -f /swapfile
        sed -i '\|/swapfile none swap sw 0 0|d' /etc/fstab
    fi

    fallocate -l ${size}G /swapfile

    chmod 600 /swapfile

    mkswap /swapfile

    swapon /swapfile

    swapon --show

    free -h
    df -h

    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab >/dev/null

    cat /etc/fstab

    sysctl vm.swappiness=10

    sed -i '/^vm.swappiness=/d' /etc/sysctl.conf
    echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf >/dev/null

    sed -i '/^vm.vfs_cache_pressure=/d' /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf >/dev/null

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

# ================= OPTION 8 =================
create_many_users() {
    echo ">>> Tao nhieu user ARO"
    echo ">>> Option nay chi tao user, KHONG cai lai ARO/XRDP"
    echo ""

    read -p "Nhap prefix user, vi du aro: " prefix
    read -p "Nhap so bat dau, vi du 1: " start
    read -p "Nhap so ket thuc, vi du 30: " end
    read -s -p "Nhap password chung: " pass
    echo ""

    if [[ -z "$prefix" || -z "$start" || -z "$end" || -z "$pass" ]]; then
        echo ">>> Thieu thong tin!"
        return
    fi

    if ! [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]]; then
        echo ">>> So bat dau/ket thuc phai la so!"
        return
    fi

    if [[ "$start" -gt "$end" ]]; then
        echo ">>> So bat dau lon hon so ket thuc!"
        return
    fi

    echo ""
    echo ">>> Se tao user tu ${prefix}${start} den ${prefix}${end}"
    echo ">>> Vi du: ${prefix}${start}, ${prefix}$((start+1)), ... ${prefix}${end}"
    echo ">>> Password chung se duoc ap dung cho tat ca user moi."
    echo ""

    read -p "Ban chac chan muon tiep tuc? (y/n): " ok
    if [[ "$ok" != "y" && "$ok" != "Y" ]]; then
        echo ">>> Da huy."
        return
    fi

    echo ""
    echo ">>> Bat dau tao user..."

    created_count=0
    skipped_count=0

    for i in $(seq "$start" "$end"); do
        user="${prefix}${i}"

        if id "$user" >/dev/null 2>&1; then
            echo ">>> $user da ton tai, bo qua."
            skipped_count=$((skipped_count+1))
            continue
        fi

        adduser --disabled-password --gecos "" "$user" >/dev/null 2>&1
        echo "$user:$pass" | chpasswd
        usermod -aG sudo "$user"

        echo "startxfce4" > /home/$user/.xsession
        chmod 644 /home/$user/.xsession
        chown "$user:$user" /home/$user/.xsession

        mkdir -p /home/$user/.config
        mkdir -p /home/$user/.local/share/applications
        chown -R "$user:$user" /home/$user

        echo "User: $user | Pass: $pass" >> /root/user_info.txt

        echo ">>> Da tao $user"
        created_count=$((created_count+1))
    done

    echo ""
    echo ">>> Restart XRDP 1 lan sau khi tao xong tat ca user..."
    systemctl restart xrdp

    echo ""
    echo "==========================================================="
    echo ">>> Tao nhieu user xong!"
    echo ">>> User moi da tao: $created_count"
    echo ">>> User da ton tai bo qua: $skipped_count"
    echo ">>> Thong tin da luu tai /root/user_info.txt"
    echo "==========================================================="
    echo ""

    echo "Danh sach user theo prefix '$prefix':"
    ls /home | grep "^$prefix" | sort -V 2>/dev/null

    echo ""
    echo "Tong so user theo prefix '$prefix':"
    ls /home | grep "^$prefix" | wc -l
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
    8) create_many_users ;;
    0) exit ;;
    *) echo "Lua chon khong hop le!" ;;
esac
