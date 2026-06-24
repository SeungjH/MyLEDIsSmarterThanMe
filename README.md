# Mac Lang LED

A lightweight, zero-CPU background daemon for macOS that uses the physical Caps Lock LED to indicate your active keyboard layout. It hooks directly into macOS's native Swift notification center to toggle the light instantly, without forcing your typing into ALL CAPS.

## Features
* **0% CPU Usage:** Event-driven architecture uses zero resources while idling.
* **Instantaneous:** Hooks natively into Apple's `TIS` input sources for zero-latency switching.
* **Native Compatibility:** Designed to work perfectly alongside the native macOS *"Use the Caps Lock key to switch to and from [Language]"* setting.

## Prerequisites
Ensure the Xcode Command Line Tools are installed on your Mac. Open Terminal and run:
```bash
xcode-select --install
```

## Installation
1. Clone this repository to your local machine:
```bash
git clone [https://github.com/SeungjH/mac-lang-led.git](https://github.com/SeungjH/mac-lang-led.git)
cd mac-lang-led
```
2. Make the installer executable and run it:
```bash
chmod +x install.sh
./install.sh
```

## Customization
By default, the daemon turns the LED **ON** for the `US` English layout and **OFF** for everything else. 
If your primary language uses a different internal layout ID (e.g., `ABC`), open `fast_led.swift` and modify the `"US"` string to match your desired ID. Run `./install.sh` again to apply the changes.

## Uninstallation
To completely remove the daemon and all associated background files:
```bash
chmod +x uninstall.sh
./uninstall.sh
```

## Credits
This project relies on the underlying hardware manipulation binary [setledsmac](https://github.com/damieng/setledsmac) by damieng.
