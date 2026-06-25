cat << 'EOF' > fast_led.swift
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

// 2. The Instant Event Listener (Replaces the slow timer)
DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
    object: nil,
    queue: .main
) { _ in
    enforceLED()
}

// 3. The Wake Override (Waits for USB hardware to power up)
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: nil
) { _ in
    let delays: [Double] = [1.0, 2.5]
    for delay in delays {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            enforceLED()
        }
    }
}

RunLoop.main.run()
EOF
