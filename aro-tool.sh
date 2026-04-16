#!/bin/bash

clear
echo "==========================================================="
echo "        aro thuyktutt github"
echo "==========================================================="
echo ""
echo "1) Cai dat ARO Desktop + XRDP"
echo "2) Tao SWAP RAM (1-4GB)"
echo "3) Auto XRDP sau reboot (khong can login)"
echo "4) Dang cap nhat..."
echo "5) Dang cap nhat..."
echo "6) Dang cap nhat..."
echo "7) Dang cap nhat..."
echo "0) Thoat"
echo ""
read -p "Chon option: " choice

# ================= OPTION 1 =================
install_aro() {
    echo ">>> Bat dau cai dat ARO..."

    sudo apt update && sudo apt upgrade -y

    # XFCE
    sudo apt install xfce4 xfce4-goodies -y

    # Lib
    sudo apt install dbus-x11 x11-xserver-utils -y

    # XRDP
    sudo apt install xrdp -y

    echo "startxfce4" > ~/.xsession
    chmod 644 ~/.xsession

    sudo systemctl enable xrdp
    sudo systemctl start xrdp

    # Download ARO
    wget https://download.aro.network/files/packages/linux/ARO_Desktop_latest_debian.deb

    # Install
    sudo apt install ./ARO_Desktop_latest_debian.deb -y

    # Create users
    echo ">>> Tao user aro"
    sudo adduser aro

    echo ">>> Tao user nene"
    sudo adduser nene

    # Sudo quyền
    sudo usermod -aG sudo aro
    sudo usermod -aG sudo nene

    # XFCE cho user
    echo "startxfce4" | sudo tee /home/aro/.xsession
    sudo chmod 644 /home/aro/.xsession
    sudo chown aro:aro /home/aro/.xsession

    echo "startxfce4" | sudo tee /home/nene/.xsession
    sudo chmod 644 /home/nene/.xsession
    sudo chown nene:nene /home/nene/.xsession

    sudo systemctl restart xrdp

    echo ">>> DONE! XRDP login user: aro / nene"
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

    echo ">>> Tao swap ${size}G..."

    sudo fallocate -l ${size}G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile

    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

    free -h
}

# ================= OPTION 3 =================
auto_xrdp() {
    echo ">>> Setup XRDP tu dong sau reboot..."

    sudo systemctl enable xrdp
    sudo systemctl enable dbus

    # fix den man hinh
    echo "startxfce4" > ~/.xsession

    # tao service dam bao chay lai
    sudo bash -c 'cat > /etc/systemd/system/xrdp-fix.service <<EOF
[Unit]
Description=Fix XRDP Session
After=network.target

[Service]
ExecStart=/bin/bash -c "echo startxfce4 > /root/.xsession"
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable xrdp-fix

    sudo systemctl restart xrdp

    echo ">>> DONE! Reboot van vao duoc XRDP"
}

# ================= RUN =================
case $choice in
    1) install_aro ;;
    2) swap_ram ;;
    3) auto_xrdp ;;
    0) exit ;;
    *) echo "Lua chon khong hop le!" ;;
esac
