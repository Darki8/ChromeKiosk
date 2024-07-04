#!/bin/bash

apt install software-properties-common apt-transport-https ca-certificates curl -y
# Install Google Chrome
curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome.gpg >> /dev/null
echo deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main | sudo tee /etc/apt/sources.list.d/google-chrome.list

# Install plymouth
apt install -y plymouth plymouth-themes
# Set Theme to spinning wheel
plymouth-set-default-theme -R spinner
# Update grub
update-grub2

# Change GRUB settings
if [ -e "/etc/default/grub" ]; then
  sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
  sed -i 's/GRUB_CMD_LINUX_DEFAULT="quiet"/GRUB_CMD_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
fi

# Install feh for Background image
apt install feh


# Update package list
apt update

# Install required software
apt-get install -y \
	unclutter \
	xorg \
	google-chrome-stable \
	openbox \
	lightdm \
	locales

# Create necessary directory
mkdir -p /home/kiosk/.config/openbox

# Create group if not exists
getent group kiosk || groupadd kiosk

# Create user if not exists
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash 

# Set correct ownership
chown -R kiosk:kiosk /home/kiosk

# Move Image from Current admin to kiosk
mv "$(pwd)/UPK_Basel_Logo-edit.png" /home/kiosk

# Disable virtual console switching
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# Configure LightDM for autologin and Openbox session
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF

# Configure Openbox autostart
if [ -e "/home/kiosk/.config/openbox/autostart" ]; then
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
fi
cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

# Setup Network
ifconfig eth0 up
dhclient

#set Backgound image
feh --bg-scale /home/kiosk/UPK_Basel_Logo.png &

while :
do
  xrandr --auto
  google-chrome \
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
  sleep 2
done &
EOF

# Create Chrome policy directory
mkdir -p /etc/opt/chrome/policies/managed
# Create Chrome policy for bookmarks and URL whitelist
cat > /etc/opt/chrome/policies/managed/policy.json << EOF
{
  "URLAllowlist": ["chrome:*","https://sbb.ch/", "https://chefkoch.de/", "https://wikipedia.org/", "https://akad.ch/",  "https://vhs-lernportal.de/"],
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
    {
      "name": "SBB",
      "url": "https://www.sbb.ch/"
    },
    {
      "name": "Chefkoch",
      "url": "https://chefkoch.de/"
    },
    {
      "name": "Wikipedia",
      "url": "https://wikipedia.org/"
    },
    {
      "name": "AKAD",
      "url": "https://akad.ch/"
    },
    {
      "name": "VHS-lernportal",
      "url": "https://vhs-lernportal.de/"
    }
  ]
}
EOF

mkdir -p /home/kiosk/.config/google-chrome/Default
cat > /home/kiosk/.config/google-chrome/Default/Bookmarks << EOF
{
   "checksum": "fe887b6e1145bdc61b6bafe20bdb81fa",
   "roots": {
      "bookmark_bar": {
         "children": [ {
            "date_added": "13183642538941632",
            "date_last_used": "0",
            "guid": "00000000-0000-0000-0000-000000000001",
            "id": "2",
            "name": "Sbb",
            "type": "url",
            "url": "https://sbb.ch/"
         }, {
            "date_added": "13183642538941632",
            "date_last_used": "0",
            "guid": "00000000-0000-0000-0000-000000000002",
            "id": "3",
            "name": "Chefkoch",
            "type": "url",
            "url": "https://chefkoch.de/"
         }, {
            "date_added": "13183642538941632",
            "date_last_used": "0",
            "guid": "00000000-0000-0000-0000-000000000003",
            "id": "4",
            "name": "Wikipedia",
            "type": "url",
            "url": "https://wikipedia.org/"
         }, {
            "date_added": "13183642538941632",
            "date_last_used": "0",
            "guid": "00000000-0000-0000-0000-000000000004",
            "id": "5",
            "name": "AKAD",
            "type": "url",
            "url": "https://akad.ch/"
         }, {
            "date_added": "13183642538941632",
            "date_last_used": "0",
            "guid": "00000000-0000-0000-0000-000000000005",
            "id": "6",
            "name": "VHS-Lernportal",
            "type": "url",
            "url": "https://vhs-lernportal.de/"
         } ],
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
chown -R kiosk:kiosk /etc/opt/chrome/policies/managed
echo "Done!"

