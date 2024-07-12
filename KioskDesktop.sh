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
apt-get remove -y plasma-discover 

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

# Create Chrome Bookmarks
mkdir -p /home/kiosk/.config/google-chrome/Default
cat > /home/kiosk/.config/google-chrome/Default/Bookmarks << EOF
{
"checksum": "fe887b6e1145bdc61b6bafe20bdb81fa",
   "roots": {
      "bookmark_bar": {
        "children": [ 
	 	{"date_added": "13183642538941632","date_last_used": "0","guid": "00000000-0000-0000-0000-000000000001","id": "2","name": "Sbb","type": "url","url": "https://sbb.ch/"},
   		{"date_added": "13183642538941632","date_last_used": "0","guid": "00000000-0000-0000-0000-000000000002","id": "3","name": "Chefkoch","type": "url","url": "https://chefkoch.de/"}, 
     		{"date_added": "13183642538941632","date_last_used": "0","guid": "00000000-0000-0000-0000-000000000003","id": "4","name": "Wikipedia","type": "url","url": "https://wikipedia.org/"}, 
	 	{"date_added": "13183642538941632","date_last_used": "0","guid": "00000000-0000-0000-0000-000000000004","id": "5","name": "AKAD","type": "url","url": "https://akad.ch/"}, 
		{"date_added": "13183642538941632","date_last_used": "0","guid": "00000000-0000-0000-0000-000000000005","id": "6","name": "VHS-Lernportal","type": "url","url": "https://vhs-lernportal.de/"} 
  	],
        "date_added": "13183642538941632",
        "date_last_used": "0",
        "date_modified": "13183642538941632",
        "guid": "0bc5d13f-2cba-5d74-951f-3f233fe6c908",
        "id": "1",
        "name": "Lesezeichenleiste",
        "type": "folder"
      },
      "other": {
         "children": [  ],
         "date_added": "13183642538941632",
         "date_last_used": "0",
         "date_modified": "13183642538941632",
         "guid": "82b081ec-3dd3-529c-8475-ab6c344590dd",
         "id": "7",
         "name": "Weitere Lesezeichen",
         "type": "folder"
      },
      "synced": {
         "children": [  ],
         "date_added": "13183642538941632",
         "date_last_used": "0",
         "date_modified": "13183642538941632",
         "guid": "4cf2e351-0e85-532b-bb37-df045d8f8d0f",
         "id": "8",
         "name": "Mobile Lesezeichen",
         "type": "folder"
      }
   },
   "version": 1
}
EOF


# Allow access to common directories
mkdir -p /home/kiosk/Documents /home/kiosk/Downloads
chown -R kiosk:kiosk /home/kiosk/Documents /home/kiosk/Downloads

# Configure kiosk mode for KDE Plasma
#mkdir -p /etc/xdg
#cat > /home/kiosk/.config/kdeglobals << EOF
#[KDE Action Restrictions][$i]
#action/lock_screen=false
#action/start_new_session=false
#action/switch_user=false
#action/sleep=false
#action/hibernate=false
#shell_access=false
#action/run_command=false
#run_command=false
#action/properties=false
#action/file_properties=false
#action/dolphin/properties=false
#action/file/properties=false
#EOF

# Prevent access to specific System Settings modules
#mkdir -p /etc/xdg/kiosk
#cat > /etc/xdg/kiosk/kioskrc << EOF
#[KDE Control Module Restrictions][$i]
#kcmshell5=kcm_printer_manager.desktop
#kcm_powerdevilprofilesconfig.desktop=false
#kcm_powerdevilactivitiesconfig.desktop=false
#powerdevilglobalconfig.desktop=false
#kcm_activities.desktop=false
#kcm_fonts.desktop=false
#kcm_kscreen.desktop=false
#kcm_users.desktop=false
#kcm_networkmanagement.desktop=false
#kcm_wifi.desktop=false
#kcm_bluetooth.desktop=false
#kcm_desktoptheme.desktop=false
#kcm_workspace.desktop=false
#kcm_lookandfeel.desktop=false
#kcm_notifications.desktop=false
#kcm_regionandlang.desktop=false
#kcm_style.desktop=false
#kcm_keys.desktop=false
#kcm_touchpad.desktop=false
#kcm_mouse.desktop=false
#kcm_solid_actions.desktop=false
#kcm_sddm.desktop=false
#kcm_about-distro.desktop=false

#[KDE Action Restrictions][$i]
#action/kdesystemsettings=false
#action/systemsettings=false

#[General]
#immutability=2
#EOF

# RESTICT USER
mv /etc/kde5rc /etc/kde5rc.BAK
cat > /etc/kde5rc << EOF
[KDE Action Restrictions][$i]
action/options_configure=false
action/properties=false
action/file_save=true
action/file_save_as=true
action/file_revert=true
action/file_close=true
action/file_print=true
action/file_print_preview=true
action/options_show_toolbar=true
action/fullscreen=true

[KDE Resource Restrictions][$i]
print/properties=true

[KDE Control Module Restrictions][$i]
mouse.desktop=false
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

# Configure KDE Plasma panel and desktop layout
mkdir -p /etc/xdg
cat > /etc/xdg/plasma-org.kde.plasma.desktop-appletsrc << EOF
[Containments][1]
activityId=3c740d54-fc8d-4064-86da-42ebb23a559d
formfactor=0
immutability=2
lastScreen=0
location=0
plugin=org.kde.plasma.folder
wallpaperplugin=org.kde.image

[Containments][1][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/Next/contents/images/1920x1080.png

[Containments][2]
activityId=3c740d54-fc8d-4064-86da-42ebb23a559d
formfactor=2
immutability=2
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][2][Applets][20]
immutability=2
plugin=org.kde.plasma.kickoff

[Containments][2][Applets][21]
immutability=2
plugin=org.kde.plasma.showdesktop

[Containments][2][Applets][22]
immutability=2
plugin=org.kde.plasma.systemtray

[Containments][2][Applets][22][Configuration][General]
PreloadWeight=85
SystrayContainmentId=8

[Containments][2][Applets][23]
immutability=2
plugin=org.kde.plasma.icontasks

[Containments][2][Applets][23][Configuration][General]
launchers=applications:systemsettings.desktop,preferred://filemanager

[Containments][8]
activityId=3c740d54-fc8d-4064-86da-42ebb23a559d
formfactor=2
immutability=2
lastScreen=0
location=4
plugin=org.kde.plasma.private.systemtray
wallpaperplugin=org.kde.image

[ScreenMapping]
itemsOnDisabledScreens=
screenMapping=desktop:/Google-Chrome.desktop,0,3c740d54-fc8d-4064-86da-42ebb23a559d,desktop:/LibreOffice-Writer.desktop,0,3c740d54-fc8d-4064-86da-42ebb23a559d

[Containments][1]
immutability=2
EOF

# Set permissions
chown root:root /etc/xdg/plasma-org.kde.plasma.desktop-appletsrc
chmod 644 /etc/xdg/plasma-org.kde.plasma.desktop-appletsrc

# Disable edit of widgets and taskbar
qdbus org.kde.plasmashell /PlasmaShell evaluateScript "lockCorona(true)"

# Set ownership of configuration files
chown -R kiosk:kiosk /home/kiosk/.config
chmod -R 755 /home/kiosk/.config

echo "Setup complete!"
