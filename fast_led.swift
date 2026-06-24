cat << 'EOF' > ~/.local/bin/fast_led.swift
#!/usr/bin/swift
import Cocoa
import Carbon

func enforceLED() {
    let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
    let idString = Unmanaged<CFString>.fromOpaque(idPtr!).takeUnretainedValue() as String
    
    let task = Process()
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    task.executableURL = URL(fileURLWithPath: "\(home)/.local/bin/setleds")
    
    if idString.hasSuffix("US") {
        task.arguments = ["+caps"]
    } else {
        task.arguments = ["-caps"]
    }
    
    try? task.run()
    task.waitUntilExit()
}

// 1. Run immediately on load
enforceLED()

// 2. The Brute Force Timer: Re-apply the LED state every 1 second, forever.
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    enforceLED()
}

RunLoop.main.run()
EOF

launchctl unload ~/Library/LaunchAgents/com.user.langled.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.user.langled.plist
