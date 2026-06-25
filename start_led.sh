#!/bin/bash

mkdir -p ~/.local/bin

# 1. Download the hardware dependency
curl -sL -o ~/.local/bin/setleds.zip https://github.com/damieng/setledsmac/releases/download/0.4/setleds-v0.4-binary.zip
unzip -qo ~/.local/bin/setleds.zip -d ~/.local/bin/
rm ~/.local/bin/setleds.zip
chmod +x ~/.local/bin/setleds

# 2. Write the exact working Swift code
cat << 'EOF' > ~/.local/bin/fast_led.swift
import Foundation
import Cocoa
import Carbon

func enforceLED() {
    guard let sourceRef = TISCopyCurrentKeyboardInputSource() else { return }
    let source = sourceRef.takeRetainedValue()
    guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return }
    let idString = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    
    let task = Process()
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    task.executableURL = URL(fileURLWithPath: "\(home)/.local/bin/setleds")
    task.arguments = idString.hasSuffix("US") ? ["+caps"] : ["-caps"]
    try? task.run()
    task.waitUntilExit()
}

enforceLED()

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
    object: nil, queue: .main) { _ in enforceLED() }

let wakeBlock: (Notification) -> Void = { _ in
    for delay in [1.0, 3.0, 6.0, 10.0] {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { enforceLED() }
    }
}
NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: wakeBlock)
NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main, using: wakeBlock)

Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in enforceLED() }
RunLoop.main.run()
EOF

# 3. Kill any previously running instances
pkill -f "fast_led.swift" 2>/dev/null

# 4. Run it in the background and detach from the terminal
nohup swift ~/.local/bin/fast_led.swift >/dev/null 2>&1 &

echo "✅ LED script is now running in the background. You can safely close this terminal."
