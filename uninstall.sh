#!/bin/bash

PLIST_PATH="$HOME/Library/LaunchAgents/com.user.langled.plist"
BIN_DIR="$HOME/.local/bin"

echo "Removing Mac Lang LED..."

# Unload background service
launchctl unload "$PLIST_PATH" 2>/dev/null
rm -f "$PLIST_PATH"

# Remove scripts and dependencies
rm -f "$BIN_DIR/fast_led.swift"
rm -f "$BIN_DIR/setleds"

echo "Uninstallation complete."
