#!/bin/bash

# First Update System
apt-get update && apt-get upgrade -y

# Install All Required Packages 
apt-get install -y \
	xorg \
	openbox \
	lightdm \
	locales \
 	software-properties-common \
  apt-transport-https \
  ca-certificates \
  curl \
  plymouth \
  plymouth-themes

# Install KDE Plasma Desktop Environment
apt-get install -y kde-plasma-desktop

# Install LibreOffice
apt-get install -y libreoffice

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


if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=plasma
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


# Set ownership of Chrome policy directory
chown -R kiosk:kiosk /etc/opt/chrome/policies/managed /home/kiosk/.config


# Set permissions for desktop shortcuts
chown kiosk:kiosk /home/kiosk/Desktop/*.desktop
chmod +x /home/kiosk/Desktop/*.desktop

echo "Done!"
