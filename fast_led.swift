import Foundation
import Cocoa
import Carbon

let ledQueue = DispatchQueue(label: "com.user.langled.queue")
let home = FileManager.default.homeDirectoryForCurrentUser.path
let setledsPath = "\(home)/.local/bin/setleds"

var lastArgument: String?
var isRunningSetleds = false

func currentLEDArgument() -> String? {
    guard let sourceRef = TISCopyCurrentKeyboardInputSource() else { return nil }
    let source = sourceRef.takeRetainedValue()

    guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }

    let idString = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    print("Current input source:", idString)

    return idString.hasSuffix("US") ? "+caps" : "-caps"
}

func enforceLED(force: Bool = false) {
    guard let argument = currentLEDArgument() else { return }

    ledQueue.async {
        if isRunningSetleds {
            return
        }

        if !force && lastArgument == argument {
            return
        }

        isRunningSetleds = true
        defer { isRunningSetleds = false }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: setledsPath)
        task.arguments = [argument]

        do {
            try task.run()
        } catch {
            print("Failed to run setleds:", error)
            return
        }

        let deadline = Date().addingTimeInterval(1.0)

        while task.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        if task.isRunning {
            print("setleds timed out. Terminating.")
            task.terminate()
            return
        }

        if task.terminationStatus == 0 {
            lastArgument = argument
            print("LED updated:", argument)
        } else {
            print("setleds failed with status:", task.terminationStatus)
        }
    }
}

enforceLED(force: true)

let inputObserver = DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
    object: nil,
    queue: .main
) { _ in
    enforceLED()
}

let wakeBlock: (Notification) -> Void = { _ in
    for delay in [1.0, 3.0, 6.0, 10.0] {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            enforceLED(force: true)
        }
    }
}

let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: .main,
    using: wakeBlock
)

let screenWakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.screensDidWakeNotification,
    object: nil,
    queue: .main,
    using: wakeBlock
)

Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
    enforceLED(force: true)
}

RunLoop.main.run()
