#!/bin/bash

apt install software-properties-common apt-transport-https ca-certificates curl -y
# Install Google Chrome
curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome.gpg >> /dev/null
echo deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main | sudo tee /etc/apt/sources.list.d/google-chrome.list


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

while :
do
  xrandr --auto
  google-chrome \
    --no-first-run \
    --start-maximized \
    --disable \
    --disable-translate \
    --disable-infobars \
    --disable-suggestions-service \
    --disable-save-password-bubble \
    --disable-session-crashed-bubble \
    --incognito \
    --disable-plugins \
    --disable-sync \
    --no-default-browser-check \
    --no-first-run \
    --password-store=basic \
    --disable-extensions \
    --user-data-dir=/home/kiosk/.config/google-chrome
  sleep 5
done &
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
  "BookmarkBarEnabled": true,
  "ManagedBookmarks": [
    {
      "toplevel_name": "Managed bookmarks",
      "children": [
        {
          "name": "Sbb",
          "url": "https://sbb.ch/"
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
          "name": "VHS-Lernportal",
          "url": "https://vhs-lernportal.de/"
        }
      ]
    }
  ]
}
EOF
	
# Set ownership of Chrome policy directory
chown -R kiosk:kiosk /etc/chrome
echo "Done!"

