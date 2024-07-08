#!/bin/bash

# Install KDE Plasma Desktop Environment
apt-get install -y kde-plasma-desktop

# Install LibreOffice
apt-get install -y libreoffice

if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=plasma
EOF


# Create desktop shortcut for LibreOffice Writer
cat > /home/kiosk/Desktop/LibreOffice-Writer.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=LibreOffice Writer
Exec=libreoffice --writer
Icon=libreoffice-writer
Terminal=false
EOF

# Create desktop shortcut for LibreOffice Calc
cat > /home/kiosk/Desktop/LibreOffice-Calc.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=LibreOffice Calc
Exec=libreoffice --calc
Icon=libreoffice-calc
Terminal=false
EOF

# Create desktop shortcut for LibreOffice Impress
cat > /home/kiosk/Desktop/LibreOffice-Impress.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=LibreOffice Impress
Exec=libreoffice --impress
Icon=libreoffice-impress
Terminal=false
EOF

# Create desktop shortcut for LibreOffice Draw
cat > /home/kiosk/Desktop/LibreOffice-Draw.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=LibreOffice Draw
Exec=libreoffice --draw
Icon=libreoffice-draw
Terminal=false
EOF

# Set permissions for desktop shortcuts
chown kiosk:kiosk /home/kiosk/Desktop/*.desktop
chmod +x /home/kiosk/Desktop/*.desktop
