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
