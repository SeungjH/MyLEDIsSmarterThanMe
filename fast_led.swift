import Foundation
import Cocoa
import Carbon

// MARK: - Config

let home = FileManager.default.homeDirectoryForCurrentUser.path
let setledsPath = "\(home)/.local/bin/setleds"

// English input source 기준.
// 필요하면 "ABC" 같은 다른 layout suffix를 추가하면 됨.
let ledOnInputSourceSuffixes = ["US"]

let normalBackupInterval: TimeInterval = 60.0
let screenSaverKeepAliveInterval: TimeInterval = 3.0
let setledsTimeout: TimeInterval = 1.0

// MARK: - State

let ledQueue = DispatchQueue(label: "com.user.langled.ledQueue")

var lastLEDArgument: String?
var isRunningSetleds = false

var keepAliveTimer: Timer?
var keepAliveReasons = Set<String>()

// MARK: - Logging

func log(_ items: Any...) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let message = items.map { String(describing: $0) }.joined(separator: " ")
    print("[\(timestamp)] \(message)")
    fflush(stdout)
}

// MARK: - Input Source

func getCurrentInputSourceID() -> String? {
    guard let sourceRef = TISCopyCurrentKeyboardInputSource() else {
        log("Failed to get current keyboard input source")
        return nil
    }

    let source = sourceRef.takeRetainedValue()

    guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
        log("Failed to get input source ID")
        return nil
    }

    let idString = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    return idString
}

func desiredLEDArgument(for inputSourceID: String) -> String {
    let shouldTurnOn = ledOnInputSourceSuffixes.contains { suffix in
        inputSourceID.hasSuffix(suffix)
    }

    return shouldTurnOn ? "+caps" : "-caps"
}

// MARK: - LED Control

func runSetLEDs(_ argument: String, force: Bool = false) {
    ledQueue.async {
        if isRunningSetleds {
            log("setleds already running. Skipping.")
            return
        }

        if !force && lastLEDArgument == argument {
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
            log("Failed to run setleds:", error)
            return
        }

        let deadline = Date().addingTimeInterval(setledsTimeout)

        while task.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        if task.isRunning {
            log("setleds timed out. Terminating.")
            task.terminate()
            return
        }

        if task.terminationStatus == 0 {
            lastLEDArgument = argument
            log("LED updated:", argument)
        } else {
            log("setleds exited with status:", task.terminationStatus)
        }
    }
}

func enforceLED(force: Bool = false) {
    guard let inputSourceID = getCurrentInputSourceID() else {
        return
    }

    let argument = desiredLEDArgument(for: inputSourceID)

    log("Current input source:", inputSourceID, "->", argument)

    runSetLEDs(argument, force: force)
}

// MARK: - Screensaver / Lock Keep Alive

func startKeepAlive(reason: String) {
    keepAliveReasons.insert(reason)

    if keepAliveTimer == nil {
        log("Starting LED keep-alive. Reason:", reason)

        let timer = Timer(timeInterval: screenSaverKeepAliveInterval, repeats: true) { _ in
            enforceLED(force: true)
        }

        keepAliveTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    } else {
        log("LED keep-alive already running. Added reason:", reason)
    }

    enforceLED(force: true)
}

func stopKeepAlive(reason: String) {
    keepAliveReasons.remove(reason)

    if keepAliveReasons.isEmpty {
        log("Stopping LED keep-alive. Reason:", reason)

        keepAliveTimer?.invalidate()
        keepAliveTimer = nil

        enforceLED(force: true)
    } else {
        log("Keep-alive still needed by:", keepAliveReasons)
    }
}

// MARK: - Initial Sync

enforceLED(force: true)

// MARK: - Input Source Change Observer

let inputObserver = DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
    object: nil,
    queue: .main
) { _ in
    enforceLED()
}

// MARK: - Wake Observers

let wakeBlock: (Notification) -> Void = { _ in
    log("Wake detected. Re-syncing LED.")

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

// MARK: - Screensaver Observers

let screenSaverStartObserver = DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screensaver.didstart"),
    object: nil,
    queue: .main
) { _ in
    log("Screensaver started.")
    startKeepAlive(reason: "screensaver")
}

let screenSaverStopObserver = DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screensaver.didstop"),
    object: nil,
    queue: .main
) { _ in
    log("Screensaver stopped.")
    stopKeepAlive(reason: "screensaver")
}

// MARK: - Lock Screen Observers

let screenLockedObserver = DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screenIsLocked"),
    object: nil,
    queue: .main
) { _ in
    log("Screen locked.")
    startKeepAlive(reason: "lockscreen")
}

let screenUnlockedObserver = DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screenIsUnlocked"),
    object: nil,
    queue: .main
) { _ in
    log("Screen unlocked.")
    stopKeepAlive(reason: "lockscreen")
}

// MARK: - Normal Backup Sync

let backupTimer = Timer(timeInterval: normalBackupInterval, repeats: true) { _ in
    enforceLED(force: true)
}

RunLoop.main.add(backupTimer, forMode: .common)

// MARK: - Run

log("MyLEDIsSmarterThanMe daemon started.")
RunLoop.main.run()
