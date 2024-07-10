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
  "URLAllowlist": ["chrome://", "https://sbb.ch/", "https://chefkoch.de/", "https://wikipedia.org/", "https://akad.ch/",  "https://vhs-lernportal.de/"],
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

# Disable switching users, hibernate, and sleep options in KDE Plasma
mkdir -p /etc/xdg
cat > /home/kiosk/.config/kdeglobals << EOF
[KDE Action Restrictions][$i]
action/lock_screen=false
action/start_new_session=false
action/switch_user=false
action/sleep=false
action/hibernate=false
shell_access=false
action/run_command=false
run_command=false
action/properties=false
action/file_properties=false
action/dolphin/properties=false
action/file/properties=false
EOF

# Prevent access to specific System Settings modules
mkdir -p /etc/xdg/kiosk
cat > /etc/xdg/kiosk/kioskrc << EOF
[KDE Control Module Restrictions][$i]
kcm_powerdevilprofilesconfig.desktop=false
kcm_powerdevilactivitiesconfig.desktop=false
powerdevilglobalconfig.desktop=false
EOF

# disable autolock
cat > /home/kiosk/.config/kscreenlockerrc << EOF
[Daemon]
Autolock=false
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

# Set KDE Plasma Kiosk settings
mkdir -p /etc/xdg/plasma-workspace/env
cat > /etc/xdg/plasma-workspace/env/kde-kiosk.sh << EOF
#!/bin/bash
export KDE_SESSION_VERSION=5
export KDE_FULL_SESSION=true
EOF
chmod +x /etc/xdg/plasma-workspace/env/kde-kiosk.sh

# Overwrite Original File
mv /home/kiosk/.config/plasma-org.kde.plasma.desktop-appletsrc /home/kiosk/.config/plasma-org.kde.plasma.desktop-appletsrc.back
cat > /home/kiosk/.config/plasma-org.kde.plasma.desktop-appletsrc << EOF
[ActionPlugins][0]
RightButton;NoModifier=org.kde.contextmenu
wheel:Vertical;NoModifier=org.kde.switchdesktop

[ActionPlugins][1]
RightButton;NoModifier=org.kde.contextmenu

[Containments][1]
ItemGeometries-784x898=
ItemGeometriesHorizontal=
ItemGeometriesVertical=
activityId=3c740d54-fc8d-4064-86da-42ebb23a559d
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.folder
wallpaperplugin=org.kde.image

[Containments][2]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][2][Applets][18]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][2][Applets][19]
immutability=1
plugin=org.kde.plasma.showdesktop

[Containments][2][Applets][3]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][2][Applets][3][Configuration]
PreloadWeight=100
popupHeight=514
popupWidth=651

[Containments][2][Applets][3][Configuration][ConfigDialog]
DialogHeight=540
DialogWidth=720

[Containments][2][Applets][3][Configuration][General]
favoritesPortedToKAstats=true

[Containments][2][Applets][3][Configuration][Shortcuts]
global=Alt+F1

[Containments][2][Applets][3][Shortcuts]
global=Alt+F1

[Containments][2][Applets][4]
immutability=1
plugin=org.kde.plasma.pager

[Containments][2][Applets][5]
immutability=1
plugin=org.kde.plasma.icontasks

[Containments][2][Applets][6]
immutability=1
plugin=org.kde.plasma.marginsseparator

[Containments][2][Applets][7]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][2][Applets][7][Configuration]
PreloadWeight=100
SystrayContainmentId=8

[Containments][2][General]
AppletOrder=3;4;5;6;7;18;19

[Containments][8]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.plasma.private.systemtray
popupHeight=432
popupWidth=432
wallpaperplugin=org.kde.image

[Containments][8][Applets][10]
immutability=1
plugin=org.kde.plasma.volume

[Containments][8][Applets][10][Configuration]
PreloadWeight=70

[Containments][8][Applets][10][Configuration][General]
migrated=true

[Containments][8][Applets][11][Configuration]
PreloadWeight=42

[Containments][8][Applets][12][Configuration]
PreloadWeight=42

[Containments][8][Applets][13]
immutability=1
plugin=org.kde.plasma.devicenotifier

[Containments][8][Applets][13][Configuration]
PreloadWeight=55

[Containments][8][Applets][14][Configuration]
PreloadWeight=42

[Containments][8][Applets][15][Configuration]
PreloadWeight=42

[Containments][8][Applets][16][Configuration]
PreloadWeight=42

[Containments][8][Applets][17][Configuration]
PreloadWeight=42

[Containments][8][Applets][20][Configuration]
PreloadWeight=42

[Containments][8][Applets][21]
immutability=1
plugin=org.kde.plasma.networkmanagement

[Containments][8][Applets][21][Configuration]
PreloadWeight=55

[Containments][8][Applets][22][Configuration]
PreloadWeight=42

[Containments][8][Applets][9][Configuration]
PreloadWeight=42

[Containments][8][ConfigDialog]
DialogHeight=540
DialogWidth=720

[Containments][8][General]
extraItems=org.kde.plasma.volume,org.kde.plasma.devicenotifier,org.kde.plasma.networkmanagement
knownItems=org.kde.kdeconnect,org.kde.plasma.volume,org.kde.kscreen,org.kde.plasma.manage-inputmethod,org.kde.plasma.devicenotifier,org.kde.kupapplet,org.kde.plasma.mediacontroller,org.kde.plasma.keyboardlayout,org.kde.plasma.bluetooth,org.kde.plasma.notifications,org.kde.plasma.clipboard,org.kde.plasma.battery,org.kde.plasma.vault,org.kde.plasma.networkmanagement

[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=desktop:/Google-Chrome.desktop,0,3c740d54-fc8d-4064-86da-42ebb23a559d,desktop:/LibreOffice-Writer.desktop,0,3c740d54-fc8d-4064-86da-42ebb23a559d
EOF

echo "Done!"
