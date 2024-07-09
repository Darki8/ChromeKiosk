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
  libreoffice-writer

# Install Google Chrome
curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome.gpg >> /dev/null
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

# Create Chrome policy directory
mkdir -p /etc/opt/chrome/policies/managed
# Create Chrome policy for bookmarks and URL whitelist
cat > /etc/opt/chrome/policies/managed/policy.json << EOF
{
  "URLAllowlist": ["https://sbb.ch/", "https://chefkoch.de/", "https://wikipedia.org/", "https://akad.ch/",  "https://vhs-lernportal.de/"],
  "URLBlocklist": ["*"],
  "HomepageLocation": "https://sbb.ch/",
  "RestoreOnStartup": 4,
  "RestoreOnStartupURLs": ["https://sbb.ch/"],
  "PasswordManagerEnabled": false,
  "SavingBrowserHistoryDisabled": true,
  "BrowserAddPersonEnabled":false,
  "BrowserGuestModeEnabled":false,
  "BrowserSignin":0,
  "PrintingEnabled":false,
  "DeveloperToolsAvailability":2,
  "TaskManagerEndProcessEnabled":false,
  "DownloadRestrictions":3,
  "SharedClipboardEnabled":false,
  "NewTabPageLocation":"google.com",
  "SearchSuggestEnabled":false,
  "EditBookmarksEnabled":false,
  "BookmarkBarEnabled": true,
  "ImportBookmarks":false,
  "ManagedBookmarks": [
    {"name": "SBB","url": "https://www.sbb.ch/"},
    {"name": "Chefkoch","url": "https://chefkoch.de/"},
    {"name": "Wikipedia","url": "https://wikipedia.org/"},
    {"name": "AKAD","url": "https://akad.ch/"},
    {"name": "VHS-lernportal","url": "https://vhs-lernportal.de/"}
  ]
}
EOF

# Set ownership of Chrome policy directory
chown -R kiosk:kiosk /etc/opt/chrome/policies/managed /home/kiosk/.config

# Set permissions for desktop shortcuts
chown kiosk:kiosk /home/kiosk/Desktop/*.desktop
chmod +x /home/kiosk/Desktop/*.desktop

# Allow access to common directories
mkdir -p /home/kiosk/Documents /home/kiosk/Downloads
chown -R kiosk:kiosk /home/kiosk/Documents /home/kiosk/Downloads

# Restrict user permissions
echo "kiosk ALL=(ALL) NOPASSWD: /usr/bin/libreoffice, /usr/bin/google-chrome" | sudo tee /etc/sudoers.d/kiosk
chmod 0440 /etc/sudoers.d/kiosk

# Disable switching users, shutdown, and reboot options in KDE Plasma
mkdir -p /etc/kde5
cat > /etc/kde5/kioskrc << EOF
[KDE Action Restrictions][$i]
logout=false
lock_screen=false
switch_user=false
suspend=false
hibernate=false
reboot=false
poweroff=false
EOF

# Apply restrictions to KDE Plasma
cat > /etc/xdg/kdeglobals << EOF
[KDE Action Restrictions]
logout=false
lock_screen=false
switch_user=false
suspend=false
hibernate=false
reboot=false
poweroff=false
EOF

# Setup udiskie for automounting USB devices
cat > /home/kiosk/.config/autostart/udiskie.desktop << EOF
[Desktop Entry]
Type=Application
Exec=udiskie
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=udiskie
Name=udiskie
Comment[en_US]=Automount USB devices
Comment=Automount USB devices
EOF

echo "Done!"
