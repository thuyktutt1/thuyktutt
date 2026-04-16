#!/bin/bash

# B1: Update hệ thống
sudo apt update && sudo apt upgrade -y

# B2: Cài XFCE (giao diện nhẹ)
sudo apt install xfce4 xfce4-goodies -y

# B3: Cài thư viện cần thiết
sudo apt install dbus-x11 x11-xserver-utils -y

# B4: Cài XRDP (remote desktop)
sudo apt install xrdp -y

# B5: Set XFCE làm mặc định
echo "startxfce4" > ~/.xsession
chmod 644 ~/.xsession

# B6: Bật XRDP
sudo systemctl enable xrdp
sudo systemctl start xrdp

# B7: Tải ARO Desktop
wget https://download.aro.network/files/packages/linux/ARO_Desktop_latest_debian.deb

# B8: Cài ARO
sudo apt install ./ARO_Desktop_latest_debian.deb -y

echo "DONE"
