# Mac Lang LED

A lightweight, zero-CPU background daemon for macOS that uses the physical Caps Lock LED to indicate your active keyboard layout. It hooks directly into macOS's native Swift notification center to toggle the light instantly, without forcing your typing into ALL CAPS.

## Features
* **0% CPU Usage:** Event-driven architecture uses zero resources while idling.
* **Instantaneous:** Written in Swift to hook natively into Apple's `TIS` input sources.
* **Native Compatibility:** Designed to work perfectly alongside the native macOS *"Use the Caps Lock key to switch to and from [Language]"* setting.

## Prerequisites
Ensure Xcode Command Line Tools are installed on your Mac:
```bash
xcode-select --install
Installation
Clone this repository to your local machine:

Bash
git clone [https://github.com/YOUR_USERNAME/mac-lang-led.git](https://github.com/YOUR_USERNAME/mac-lang-led.git)
cd mac-lang-led
Make the installer executable and run it:

Bash
chmod +x install.sh
./install.sh
Customization
By default, the daemon turns the LED ON for the US English layout and OFF for everything else.
If your primary language uses a different internal layout ID (e.g., ABC), open fast_led.swift and modify the "US" string to match your desired ID. Run ./install.sh again to apply the changes.

Uninstallation
To completely remove the daemon and all associated background files:

Bash
chmod +x uninstall.sh
./uninstall.sh
Credits
This project relies on the underlying hardware manipulation binary setledsmac by damieng.
