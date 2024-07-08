#!/bin/bash

# First Update System
apt-get update && apt-get upgrade -y

# Install All Required Packages 
apt-get install -y \
    feh \
    unclutter \
    xorg \
    xfce4 \
    xfce4-goodies \
    lightdm \
    locales \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    curl \
    plymouth \
    plymouth-themes \
    libreoffice \
    cups \
    system-config-printer

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
mkdir -p /home/kiosk/.config/openbox /home/kiosk/.config/autostart /home/kiosk/.config/xfce4/xfconf/xfce-perchannel-xml /home/kiosk/Desktop
chown -R kiosk:kiosk /home/kiosk
mv "$(pwd)/Logo.png" /home/kiosk/Logo.png

# Disable virtual console switching
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# Configure LightDM for autologin and XFCE session
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=xfce
EOF

# Configure XFCE panel to be at the bottom and include shortcuts
cat > /home/kiosk/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string" value="p=8;x=0;y=0"/>
    <property name="lockPanel" type="bool" value="true"/>
    <property name="plugin-ids" type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
    </property>
    <property name="length" type="int" value="100"/>
    <property name="position-locked" type="bool" value="true"/>
    <property name="size" type="int" value="40"/>
  </property>
  <property name="plugins">
    <property name="plugin-1" type="empty">
      <property name="type" type="string" value="applicationsmenu"/>
      <property name="menu-items" type="array">
        <value type="string" value="chrome.desktop"/>
        <value type="string" value="libreoffice-writer.desktop"/>
        <value type="string" value="libreoffice-calc.desktop"/>
        <value type="string" value="libreoffice-impress.desktop"/>
      </property>
    </property>
    <property name="plugin-2" type="empty">
      <property name="type" type="string" value="tasklist"/>
    </property>
    <property name="plugin-3" type="empty">
      <property name="type" type="string" value="clock"/>
    </property>
  </property>
</channel>
EOF

# Create desktop icons for Chrome and LibreOffice
cat > /home/kiosk/Desktop/chrome.desktop << EOF
[Desktop Entry]
Type=Application
Name=Google Chrome
Exec=/usr/bin/google-chrome
Icon=google-chrome
Terminal=false
EOF

cat > /home/kiosk/Desktop/libreoffice-writer.desktop << EOF
[Desktop Entry]
Type=Application
Name=LibreOffice Writer
Exec=/usr/bin/libreoffice --writer
Icon=libreoffice-writer
Terminal=false
EOF

cat > /home/kiosk/Desktop/libreoffice-calc.desktop << EOF
[Desktop Entry]
Type=Application
Name=LibreOffice Calc
Exec=/usr/bin/libreoffice --calc
Icon=libreoffice-calc
Terminal=false
EOF

cat > /home/kiosk/Desktop/libreoffice-impress.desktop << EOF
[Desktop Entry]
Type=Application
Name=LibreOffice Impress
Exec=/usr/bin/libreoffice --impress
Icon=libreoffice-impress
Terminal=false
EOF

# Mark desktop files as executable to avoid "Untrusted Application Launcher" message
chmod +x /home/kiosk/Desktop/chrome.desktop
chmod +x /home/kiosk/Desktop/libreoffice-writer.desktop
chmod +x /home/kiosk/Desktop/libreoffice-calc.desktop
chmod +x /home/kiosk/Desktop/libreoffice-impress.desktop

# Configure the system to disable logout, suspend, and user switching
cat > /home/kiosk/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-session" version="1.0">
  <property name="logout" type="empty">
    <property name="Prompt" type="bool" value="false"/>
    <property name="ShowSuspend" type="bool" value="false"/>
    <property name="ShowHibernate" type="bool" value="false"/>
    <property name="ShowShutdown" type="bool" value="false"/>
    <property name="ShowRestart" type="bool" value="false"/>
    <property name="ShowLogout" type="bool" value="false"/>
    <property name="ShowSwitchUser" type="bool" value="false"/>
  </property>
</channel>
EOF

# Set up Chrome policies
mkdir -p /etc/opt/chrome/policies/managed
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
  "NewTabPageLocation": "https://google.com",
  "SearchSuggestEnabled": false,
  "EditBookmarksEnabled": false,
  "BookmarkBarEnabled": true,
  "ImportBookmarks": false,
  "ManagedBookmarks": [
    {"name": "SBB", "url": "https://www.sbb.ch/"},
    {"name": "Chefkoch", "url": "https://chefkoch.de/"},
    {"name": "Wikipedia", "url": "https://wikipedia.org/"},
    {"name": "AKAD", "url": "https://akad.ch/"},
    {"name": "VHS-lernportal", "url": "https://vhs-lernportal.de/"}
  ]
}
EOF

# Set up Chrome bookmarks
mkdir -p /home/kiosk/.config/google-chrome/Default
cat > /home/kiosk/.config/google-chrome/Default/Bookmarks << EOF
{
  "checksum": "fe887b6e1145bdc61b6bafe20bdb81fa",
  "roots": {
    "bookmark_bar": {
      "children": [
        {"date_added": "13183642538941632","guid": "00000000-0000-0000-0000-000000000001","id": "2","name": "Sbb","type": "url","url": "https://sbb.ch/"},
        {"date_added": "13183642538941632","guid": "00000000-0000-0000-0000-000000000002","id": "3","name": "Chefkoch","type": "url","url": "https://chefkoch.de/"},
        {"date_added": "13183642538941632","guid": "00000000-0000-0000-0000-000000000003","id": "4","name": "Wikipedia","type": "url","url": "https://wikipedia.org/"},
        {"date_added": "13183642538941632","guid": "00000000-0000-0000-0000-000000000004","id": "5","name": "AKAD","type": "url","url": "https://akad.ch/"},
        {"date_added": "13183642538941632","guid": "00000000-0000-0000-0000-000000000005","id": "6","name": "VHS-Lernportal","type": "url","url": "https://vhs-lernportal.de/"}
      ],
      "date_added": "13183642538941632",
      "date_modified": "13183642538941632",
      "guid": "0bc5d13f-2cba-5d74-951f-3f233fe6c908",
      "id": "1",
      "name": "Lesezeichenleiste",
      "type": "folder"
    },
    "other": {
      "children": [],
      "date_added": "13183642538941632",
      "date_modified": "13183642538941632",
      "guid": "82b081ec-3dd3-529c-8475-ab6c344590dd",
      "id": "7",
      "name": "Weitere Lesezeichen",
      "type": "folder"
    },
    "synced": {
      "children": [],
      "date_added": "13183642538941632",
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

# Set ownership of directories
chown -R kiosk:kiosk /etc/opt/chrome/policies/managed /home/kiosk/.config /home/kiosk/Desktop

echo "Done!"
