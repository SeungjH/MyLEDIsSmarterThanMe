#!/bin/bash
set -euo pipefail

APP_NAME="MyLEDIsSmarterThanMe"
LABEL="com.user.langled"

BIN_DIR="$HOME/.local/bin"
STATE_DIR="$HOME/.local/state/$APP_NAME"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

BINARY_PATH="$BIN_DIR/langled"
INSTALLED_SWIFT="$BIN_DIR/fast_led.swift"
SETLEDS_PATH="$BIN_DIR/setleds"

PURGE=false

if [ "${1:-}" = "--purge" ]; then
    PURGE=true
fi

echo "Removing $APP_NAME..."

# Stop LaunchAgent
launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
launchctl unload "$PLIST_PATH" 2>/dev/null || true

# Kill current and legacy versions
pkill -f "fast_led.swift" 2>/dev/null || true
pkill -f "swift .*fast_led" 2>/dev/null || true
pkill -f "$BINARY_PATH" 2>/dev/null || true
pkill -x "setleds" 2>/dev/null || true

# Remove app files
rm -f "$PLIST_PATH"
rm -f "$BINARY_PATH"
rm -f "$INSTALLED_SWIFT"

# By default, keep setleds so reinstall/start is easier.
# Use ./uninstall.sh --purge to remove everything.
if [ "$PURGE" = true ]; then
    rm -f "$SETLEDS_PATH"
    rm -rf "$STATE_DIR"
    echo "Purged setleds and logs."
else
    echo "Preserved setleds and logs."
    echo "To remove everything, run:"
    echo "  ./uninstall.sh --purge"
fi

echo "Uninstallation complete."
