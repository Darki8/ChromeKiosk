# Kiosk Chrome Script

This script automates the setup of a Chrome kiosk environment on a Debian computer.

## Prerequisites

- A Debian-based system
- Sudo privileges

## Installation

1. Clone this repository or download the script and necessary files:
```bash
   git clone https://github.com/Darki8/ChromeKiosk.git
```
   Or download the KioskChromeScript.sh file and the any other images directly.

2. Navigate to the directory containing the script:
```bash
   cd kiosk-chrome-script
```
3. Make the script executable:
```bash
   sudo chmod +x KioskChromeScript.sh
```
## Usage

Run the script with sudo privileges:

sudo ./KioskChromeScript.sh

The script will execute and set up the Chrome kiosk environment. Please be patient and wait for the script to complete its execution.

>[!WARNING]
>There is a known Issue that the plymouth splash screen is not properly working. Reason: Unkown.

## What the Script Does

This script sets up a kiosk environment using Google Chrome on a Debian-based system. Here are the main actions performed:

1. Installs necessary software packages including Google Chrome, Plymouth, Openbox, and LightDM.
2. Configures the system for auto-login and sets up Openbox as the window manager.
3. Disables virtual console switching for added security.
4. Sets up a background image using feh.
5. Configures Google Chrome to run in kiosk mode with specific settings:
   - Starts in incognito mode
   - Disables various features like translation, infobars, and password saving
   - Sets a custom user data directory
6. Implements a URL whitelist and blacklist policy for Chrome.
7. Configures managed bookmarks and the homepage.
8. Disables certain Chrome features like printing, developer tools, and download capabilities.

## Customization

You can customize the script in several ways:

1. Background Image: Replace Logo.png with your desired background image.

2. Allowed URLs: Modify the URLAllowlist in the Chrome policy file (/etc/opt/chrome/policies/managed/policy.json) to add or remove allowed websites.

3. Homepage: Change the HomepageLocation and RestoreOnStartupURLs in the policy file to set a different homepage.

4. Bookmarks: Edit the ManagedBookmarks section in the policy file and the /home/kiosk/.config/google-chrome/Default/Bookmarks file to customize bookmarks.

5. Chrome Policies: Adjust other Chrome policies in the policy file to enable or disable specific features as needed.

6. Autostart Script: Modify /home/kiosk/.config/openbox/autostart to change startup behavior or add additional commands.

## Troubleshooting

If you encounter issues while running the script or using the kiosk setup, try these troubleshooting steps:

1. Script Execution Errors: 
   - Ensure you're running the script with sudo privileges.
   - Check for any error messages in the console output.

2. Chrome Not Starting: 
   - Verify that Google Chrome is installed correctly.
   - Check the Chrome policy file for syntax errors.

3. Autologin Not Working: 
   - Ensure LightDM is installed and configured correctly.
   - Check /etc/lightdm/lightdm.conf for proper settings.

4. Background Image Not Displaying: 
   - Confirm that the image file exists in /home/kiosk/Logo.png.
   - Ensure feh is installed and running correctly in the autostart script.

5. Network Issues: 
   - Check network configuration in the autostart script.
   - Ensure proper network drivers are installed.

6. Unwanted Features Still Accessible: 
   - Review and adjust the Chrome policy file as needed.
   - Ensure the policy file is being read by Chrome (you may need to restart the browser or system).

If problems persist, check system logs (/var/log/syslog) for more detailed error messages.

## Contributing

Contributions to improve the script are welcome. Please feel free to submit a Pull Request.

## Disclaimer

This script is provided as-is, without any warranties. Use at your own risk.
