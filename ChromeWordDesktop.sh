#!/bin/bash

# First Update System
apt-get update && apt-get upgrade -y

# Install Required Packages 
apt-get install -y \
  xorg \
  sddm \
  locales \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  curl \
  plymouth \
  plymouth-themes \
  gvfs-backends \
  udiskie \
  policykit-1 \
  kde-plasma-desktop \
  libreoffice-writer \
  firefox-esr

# Remove Discover and other unnecessary packages
apt-get remove -y plasma-discover konsole dolphin kwrite kmail

# Install Google Chrome
curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome.gpg > /dev/null
echo deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main | sudo tee /etc/apt/sources.list.d/google-chrome.list
apt-get update && apt-get install -y google-chrome-stable

# Configure Plymouth 
plymouth-set-default-theme -R spinner

# Change GRUB settings
if [ -e "/etc/default/grub" ]; then
  sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
fi

# Update grub
update-grub

# Setup kiosk user and environment
getent group kiosk || groupadd kiosk
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash 
mkdir -p /home/kiosk/.config/autostart
chown -R kiosk:kiosk /home/kiosk
mkdir -p /home/kiosk/Desktop
chown -R kiosk:kiosk /home/kiosk/Desktop

if [ -e "/etc/sddm.conf" ]; then
  mv /etc/sddm.conf /etc/sddm.conf.backup
fi
cat > /etc/sddm.conf << EOF
[Autologin]
User=kiosk
Session=plasma.desktop
EOF

# Create desktop shortcut for Google Chrome
cat > /home/kiosk/Desktop/Google-Chrome.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Chrome
Exec=/usr/bin/google-chrome \
    --no-first-run \
    --start-maximized \
    --incognito \
    --force-app-mode \
    --no-message-box \
    --disable-translate \
    --disable-infobars \
    --disable-suggestions-service \
    --disable-save-password-bubble \
    --disable-session-crashed-bubble \
    --disable-plugins \
    --disable-sync \
    --no-default-browser-check \
    --password-store=basic \
    --disable-extensions \
    --user-data-dir=/home/kiosk/.config/google-chrome
Icon=google-chrome
Terminal=false
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

# Set ownership and permissions for desktop shortcuts
chown kiosk:kiosk /home/kiosk/Desktop/*.desktop
chmod +x /home/kiosk/Desktop/*.desktop

# Make Desktop Icons Immutable
chattr +i /home/kiosk/Desktop/Google-Chrome.desktop
chattr +i /home/kiosk/Desktop/LibreOffice-Writer.desktop

# Chrome Policy Setup
mkdir -p /etc/opt/chrome/policies/managed
cat > /etc/opt/chrome/policies/managed/policy.json << EOF
{
  "URLAllowlist": ["chrome://", "https://sbb.ch/", "https://chefkoch.de/", "https://wikipedia.org/", "https://akad.ch/",  "https://vhs-lernportal.de/"],
 
