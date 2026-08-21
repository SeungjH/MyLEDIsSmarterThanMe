#!/bin/bash

PLIST_PATH="$HOME/Library/LaunchAgents/com.user.langled.plist"
BIN_DIR="$HOME/.local/bin"

echo "Removing MyLEDIsSmarterThanMe..."

launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null
launchctl unload "$PLIST_PATH" 2>/dev/null

pkill -f "fast_led.swift" 2>/dev/null
pkill -f "swift .*fast_led" 2>/dev/null
pkill -x setleds 2>/dev/null

rm -f "$PLIST_PATH"
rm -f "$BIN_DIR/fast_led.swift"
rm -f "$BIN_DIR/setleds"

echo "Uninstallation complete."
