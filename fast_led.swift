#!/usr/bin/swift
import Cocoa
import Carbon

func updateLED() {
    let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
    let idString = Unmanaged<CFString>.fromOpaque(idPtr!).takeUnretainedValue() as String
    
    let task = Process()
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    task.executableURL = URL(fileURLWithPath: "\(home)/.local/bin/setleds")
    
    // Modify "US" below if your primary layout ID differs
    if idString.hasSuffix("US") {
        task.arguments = ["+caps"]
    } else {
        task.arguments = ["-caps"]
    }
    try? task.run()
}

updateLED()

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
    object: nil,
    queue: nil
) { _ in
    updateLED()
}

RunLoop.main.run()
