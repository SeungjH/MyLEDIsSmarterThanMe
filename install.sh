#!/bin/bash
set -euo pipefail

APP_NAME="MyLEDIsSmarterThanMe"
LABEL="com.user.langled"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
STATE_DIR="$HOME/.local/state/$APP_NAME"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

SOURCE_SWIFT="$SCRIPT_DIR/fast_led.swift"
INSTALLED_SWIFT="$BIN_DIR/fast_led.swift"
BINARY_PATH="$BIN_DIR/langled"
SETLEDS_PATH="$BIN_DIR/setleds"

echo "Installing $APP_NAME..."

mkdir -p "$BIN_DIR"
mkdir -p "$STATE_DIR"
mkdir -p "$HOME/Library/LaunchAgents"

# Stop existing LaunchAgent if loaded
launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
launchctl unload "$PLIST_PATH" 2>/dev/null || true

# Kill old legacy nohup/script versions
pkill -f "fast_led.swift" 2>/dev/null || true
pkill -f "swift .*fast_led" 2>/dev/null || true
pkill -f "$BINARY_PATH" 2>/dev/null || true
pkill -x "setleds" 2>/dev/null || true

# Download setleds if missing
if [ ! -x "$SETLEDS_PATH" ]; then
    echo "Downloading setleds..."

    TMP_DIR="$(mktemp -d)"
    curl -fsSL \
        -o "$TMP_DIR/setleds.zip" \
        "https://github.com/damieng/setledsmac/releases/download/0.4/setleds-v0.4-binary.zip"

    unzip -qo "$TMP_DIR/setleds.zip" -d "$TMP_DIR"

    FOUND_SETLEDS="$(find "$TMP_DIR" -type f -name "setleds" | head -n 1)"

    if [ -z "$FOUND_SETLEDS" ]; then
        echo "Error: setleds binary was not found inside the downloaded zip."
        rm -rf "$TMP_DIR"
        exit 1
    fi

    cp "$FOUND_SETLEDS" "$SETLEDS_PATH"
    chmod +x "$SETLEDS_PATH"
    rm -rf "$TMP_DIR"
fi

# Check Swift source
if [ ! -f "$SOURCE_SWIFT" ]; then
    echo "Error: fast_led.swift not found in $SCRIPT_DIR"
    exit 1
fi

# Compile Swift daemon
if ! command -v swiftc >/dev/null 2>&1; then
    echo "Error: swiftc not found. Install Xcode Command Line Tools first:"
    echo "xcode-select --install"
    exit 1
fi

echo "Compiling fast_led.swift..."
swiftc "$SOURCE_SWIFT" -o "$BINARY_PATH"
chmod +x "$BINARY_PATH"

# Keep a copy of the Swift source for debugging
cp "$SOURCE_SWIFT" "$INSTALLED_SWIFT"
chmod +x "$INSTALLED_SWIFT"

# Create LaunchAgent
cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>

    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_PATH</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>ProcessType</key>
    <string>Background</string>

    <key>StandardOutPath</key>
    <string>$STATE_DIR/langled.out.log</string>

    <key>StandardErrorPath</key>
    <string>$STATE_DIR/langled.err.log</string>
</dict>
</plist>
PLIST

chmod 644 "$PLIST_PATH"

# Load LaunchAgent
echo "Starting LaunchAgent..."
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
launchctl kickstart -k "gui/$(id -u)/$LABEL" 2>/dev/null || true

echo ""
echo "Installation complete."
echo ""
echo "Status:"
echo "  launchctl print gui/$(id -u)/$LABEL"
echo ""
echo "Logs:"
echo "  tail -f $STATE_DIR/langled.out.log"
echo "  tail -f $STATE_DIR/langled.err.log"
echo ""
echo "Manual LED test:"
echo "  $SETLEDS_PATH +caps"
echo "  $SETLEDS_PATH -caps"
