#!/bin/bash

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# 1. Download the hardware dependency if it doesn't exist
if [ ! -f "$BIN_DIR/setleds" ]; then
    curl -sL -o "$BIN_DIR/setleds.zip" https://github.com/damieng/setledsmac/releases/download/0.4/setleds-v0.4-binary.zip
    unzip -qo "$BIN_DIR/setleds.zip" -d "$BIN_DIR/"
    rm "$BIN_DIR/setleds.zip"
    chmod +x "$BIN_DIR/setleds"
fi

# 2. Copy the Swift script from the current directory
cp fast_led.swift "$BIN_DIR/"
chmod +x "$BIN_DIR/fast_led.swift"

# 3. Kill any previously running instances
pkill -f "fast_led.swift" 2>/dev/null

# 4. Run it in the background and detach from the terminal
nohup swift "$BIN_DIR/fast_led.swift" >/dev/null 2>&1 &

echo "Installation complete. The LED script is now running in the background. You can safely close this terminal."
