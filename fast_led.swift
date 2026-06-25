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
