#!/bin/bash

# Variables
USERNAME="restricteduser"
PASSWORD="password"  # Change this to the desired password

# Update the system
echo "Updating the system..."
apt update && apt upgrade -y

# Install GNOME desktop environment and GDM
echo "Installing GNOME desktop environment..."
apt install -y gnome gdm3

# Install Google Chrome
echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# Create the user
echo "Creating user '$USERNAME'..."
useradd -m -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Configure autologin
echo "Configuring autologin for user '$USERNAME'..."
mkdir -p /etc/gdm3
cat <<EOL > /etc/gdm3/daemon.conf
[daemon]
AutomaticLoginEnable = true
AutomaticLogin = $USERNAME
EOL

# Disable screen suspension and locking
echo "Disabling screen suspension and locking..."
mkdir -p /etc/dconf/profile
cat <<EOL > /etc/dconf/profile/user
user-db:user
system-db:local
EOL

mkdir -p /etc/dconf/db/local.d
cat <<EOL > /etc/dconf/db/local.d/00-screensaver
[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/screensaver]
lock-enabled=false
EOL

# Update dconf database
echo "Updating dconf database..."
dconf update

# Remove option to change users
echo "Removing option to change users..."
mkdir -p /etc/dconf/db/local.d/locks
cat <<EOL > /etc/dconf/db/local.d/locks/screensaver
/org/gnome/desktop/screensaver/lock-enabled
/org/gnome/desktop/session/idle-delay
EOL

# Update dconf database
dconf update

# Create desktop icons
echo "Creating desktop icons for Google Chrome and LibreOffice Writer..."
DESKTOP_DIR="/home/$USERNAME/Desktop"
mkdir -p $DESKTOP_DIR

cat <<EOL > $DESKTOP_DIR/google-chrome.desktop
[Desktop Entry]
Version=1.0
Name=Google Chrome
Exec=/usr/bin/google-chrome-stable
Icon=google-chrome
Type=Application
Terminal=false
Categories=Network;WebBrowser;
EOL

cat <<EOL > $DESKTOP_DIR/libreoffice-writer.desktop
[Desktop Entry]
Version=1.0
Name=LibreOffice Writer
Exec=libreoffice --writer
Icon=libreoffice-writer
Type=Application
Terminal=false
Categories=Office;WordProcessor;
EOL

# Set permissions for desktop icons
chown $USERNAME:$USERNAME $DESKTOP_DIR/google-chrome.desktop
chown $USERNAME:$USERNAME $DESKTOP_DIR/libreoffice-writer.desktop
chmod +x $DESKTOP_DIR/google-chrome.desktop
chmod +x $DESKTOP_DIR/libreoffice-writer.desktop

# Additional security measures (optional)
echo "Additional security measures..."
# Disable user list in GDM login screen
cat <<EOL >> /etc/gdm3/greeter.dconf-defaults
[org/gnome/login-screen]
# Do not show the user list
disable-user-list=true
EOL

# Restart GDM to apply changes
echo "Restarting GDM..."
systemctl restart gdm3

echo "Setup complete. The system will now autologin into GNOME as '$USERNAME', and screen suspension and locking are disabled."
