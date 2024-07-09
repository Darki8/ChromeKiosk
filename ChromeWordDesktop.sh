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

# Remove Discover
apt-get remove -y plasma-discover

# Install Google Chrome
curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg > /dev/null
echo deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main | tee /etc/apt/sources.list.d/google-chrome.list
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
mkdir -p /home/kiosk/.config/autostart /home/kiosk/Desktop /home/kiosk/Documents /home/kiosk/Downloads

# Create SDDM config for auto-login
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
  "BrowserAddPersonEnabled": false,
  "BrowserGuestModeEnabled": false,
  "BrowserSignin": 0,
  "PrintingEnabled": false,
  "DeveloperToolsAvailability": 2,
  "TaskManagerEndProcessEnabled": false,
  "DownloadRestrictions": 3,
  "SharedClipboardEnabled": false,
  "NewTabPageLocation": "google.com",
  "SearchSuggestEnabled": false,
  "EditBookmarksEnabled": false,
  "BookmarkBarEnabled": true,
  "ImportBookmarks": false,
  "ManagedBookmarks": [
    {"name": "SBB","url": "https://www.sbb.ch/"},
    {"name": "Chefkoch","url": "https://chefkoch.de/"},
    {"name": "Wikipedia","url": "https://wikipedia.org/"},
    {"name": "AKAD","url": "https://akad.ch/"},
    {"name": "VHS-lernportal","url": "https://vhs-lernportal.de/"}
  ]
}
EOF

# Set ownership of directories and files
chown -R kiosk:kiosk /home/kiosk
chown -R root:root /etc/opt/chrome/policies

# Set permissions for desktop shortcuts
chmod +x /home/kiosk/Desktop/*.desktop

# Restrict user permissions
echo "kiosk ALL=(ALL) NOPASSWD: /usr/bin/libreoffice, /usr/bin/google-chrome" | tee /etc/sudoers.d/kiosk
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
show_system_settings=false
show_network_settings=false
show_loginout=false
show_new_session=false
show_quit=false
show_recent_documents=false
show_search=false
show_time=false
show_trash=false
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

# Prevent access to System Settings
cat > /etc/kde5/systemsettingsrc << EOF
[KDE Action Restrictions][$i]
systemsettings=false
EOF

# Configure KDE Kiosk mode
mkdir -p /etc/xdg/plasma-workspace/env
cat > /etc/xdg/plasma-workspace/env/kde-kiosk.sh << EOF
#!/bin/bash
export KDE_SESSION_VERSION=5
export KDE_FULL_SESSION=true
EOF
chmod +x /etc/xdg/plasma-workspace/env/kde-kiosk.sh

# Configure Autostart for udiskie
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

# Restrict access to specific applications
cat > /etc/xdg/plasma-workspace/env/kde-app-restrictions.sh << EOF
#!/bin/bash
if [ "\$USER" == "kiosk" ]; then
  export KDE_NO_GLOBAL_MENU=1
  export QT_QUICK_CONTROLS_STYLE=basic
  export PLASMA_USE_QT_SCALING=1
  kwriteconfig5 --file kioslaverc --group "KDE Action Restrictions" --key "shell_access" false
  kwriteconfig5 --file kioslaverc --group "KDE Action Restrictions" --key "run_command" false
  kwriteconfig5 --file kioslaverc --group "KDE Action Restrictions" --key "open_with" false
  kwriteconfig5 --file kioslaverc --group "KDE Action Restrictions" --key "open_terminal" false
  kwriteconfig5 --file kioslaverc --group "KDE Action Restrictions" --key "access_kmenuedit" false
fi
EOF
chmod +x /etc/xdg/plasma-workspace/env/kde-app-restrictions.sh

echo "Done!"
