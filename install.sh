#!/bin/bash

# Define paths
BIN_DIR="$HOME/.local/bin"
PLIST_PATH="$HOME/Library/LaunchAgents/com.user.langled.plist"

echo "Setting up MyLEDIsSmarterThanMe..."

# Create local bin directory
mkdir -p "$BIN_DIR"

# Download and install setledsmac dependency
echo "Downloading hardware dependency..."
curl -sL -o "$BIN_DIR/setleds.zip" https://github.com/damieng/setledsmac/releases/download/0.4/setleds-v0.4-binary.zip
unzip -qo "$BIN_DIR/setleds.zip" -d "$BIN_DIR/"
rm "$BIN_DIR/setleds.zip"
chmod +x "$BIN_DIR/setleds"

# Install Swift script
echo "Installing Swift daemon..."
cp fast_led.swift "$BIN_DIR/"
chmod +x "$BIN_DIR/fast_led.swift"

# Clean up any stuck processes before generating the new service
echo "Clearing old processes..."
launchctl unload "$PLIST_PATH" 2>/dev/null
pkill -f fast_led.swift 2>/dev/null

# Generate LaunchAgent configuration
echo "Configuring background service..."
cat << LAUNCH_AGENT_EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.langled</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_DIR/fast_led.swift</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/langled_output.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/langled_error.log</string>
</dict>
</plist>
LAUNCH_AGENT_EOF

# Restart LaunchAgent
launchctl load "$PLIST_PATH"

echo "Installation complete! The background daemon is now active."
