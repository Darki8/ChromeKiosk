#!/bin/bash

# First Update System
apt-get update && apt-get upgrade -y

# Install Required Packages 
apt-get install -y \
  xorg \
  openbox \
  sddm \
  locales \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  curl \
  plymouth \
  plymouth-themes \
  gvfs-backends \
  udiskie

# Install KDE Plasma Desktop Environment
apt-get install -y kde-plasma-desktop

# Install LibreOffice Writer only
apt-get install -y libreoffice-writer

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
mkdir -p /home/kiosk/.config/openbox
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

# Lock down the system by configuring Openbox to restrict access
cat > /home/kiosk/.config/openbox/autostart << EOF
# Disable screensaver and power management
xset s off
xset s noblank
xset -dpms

# Start Google Chrome
google-chrome &

# Start LibreOffice Writer
libreoffice --writer &

# Start udiskie for automounting USB devices
udiskie &
EOF

# Allow access to common directories
mkdir -p /home/kiosk/Documents /home/kiosk/Downloads
chown -R kiosk:kiosk /home/kiosk/Documents /home/kiosk/Downloads

# Restrict user permissions
echo "kiosk ALL=(ALL) NOPASSWD: /usr/bin/libreoffice, /usr/bin/google-chrome" | sudo tee /etc/sudoers.d/kiosk
chmod 0440 /etc/sudoers.d/kiosk

# Disable switching users, shutdown, and reboot options
echo "[Disable Ctrl+Alt+Del]
[Enable Ctrl+Alt+Backspace]
# Disable hibernation and suspend
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
# Disable user switching
allow-guest=false
greeter-hide-users=true
greeter-show-manual-login=true
session-setup-script=/usr/share/setup-session.sh" | sudo tee -a /etc/lightdm/lightdm.conf

# Create session setup script
cat > /usr/share/setup-session.sh << EOF
#!/bin/bash
# Disable user switching and other session options
gsettings set org.gnome.desktop.lockdown disable-user-switching true
gsettings set org.gnome.desktop.lockdown disable-log-out true
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
EOF
chmod +x /usr/share/setup-session.sh

# Lock down KDE Plasma settings
cat > /etc/xdg/plasma-workspace/lockdown/desktop-files.policy << EOF
[org.kde.konqueror]
restrict=false
[org.kde.systemsettings]
restrict=true
EOF

echo "Done!"
