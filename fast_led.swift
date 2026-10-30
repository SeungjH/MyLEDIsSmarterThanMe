import Foundation
import Cocoa
import Carbon
import Darwin

// MARK: - Config

let home = FileManager.default.homeDirectoryForCurrentUser.path
let setledsPath = "\(home)/.local/bin/setleds"

// English input source 기준.
// 필요하면 "ABC" 같은 다른 layout suffix를 추가하면 됨.
let ledOnInputSourceSuffixes = ["US"]

let normalBackupInterval: TimeInterval = 300.0
let setledsTimeout: TimeInterval = 1.0

// MARK: - State

let ledQueue = DispatchQueue(label: "com.user.langled.ledQueue")

var lastLEDArgument: String?

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

func runSetLEDs(_ argument: String, force: Bool = false, retriesRemaining: Int = 2) {
    ledQueue.async {
        if !force && lastLEDArgument == argument {
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: setledsPath)
        task.arguments = [argument, "-v"]

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("langled-\(UUID().uuidString).log")
        guard FileManager.default.createFile(atPath: outputURL.path, contents: nil),
              let outputHandle = try? FileHandle(forWritingTo: outputURL) else {
            log("Failed to create temporary setleds output file")
            return
        }
        defer {
            try? outputHandle.close()
            try? FileManager.default.removeItem(at: outputURL)
        }
        task.standardOutput = outputHandle

        do {
            try task.run()
        } catch {
            log("Failed to run setleds:", error)
            return
        }

        let deadline = Date().addingTimeInterval(setledsTimeout)

        while task.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.005)
        }

        if task.isRunning {
            log("setleds timed out. Terminating.")
            task.terminate()

            Thread.sleep(forTimeInterval: 0.1)
            if task.isRunning {
                kill(task.processIdentifier, SIGKILL)
            }
        }
        task.waitUntilExit()

        let output = (try? String(contentsOf: outputURL, encoding: .utf8)) ?? ""
        let confirmed = output.split(whereSeparator: \Character.isWhitespace).contains(Substring(argument))

        if task.terminationStatus == 0 && confirmed {
            lastLEDArgument = argument
            log("LED updated:", argument)
        } else {
            log(
                "setleds failed or did not confirm", argument,
                "status:", task.terminationStatus,
                "output:", String(reflecting: output)
            )

            if retriesRemaining > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    enforceLED(force: true, retriesRemaining: retriesRemaining - 1)
                }
            }
        }
    }
}

func enforceLED(force: Bool = false, retriesRemaining: Int = 2) {
    guard let inputSourceID = getCurrentInputSourceID() else {
        return
    }

    let argument = desiredLEDArgument(for: inputSourceID)

    log("Current input source:", inputSourceID, "->", argument)

    runSetLEDs(argument, force: force, retriesRemaining: retriesRemaining)
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

    for delay in [0.5, 2.0, 5.0, 10.0, 20.0, 30.0] {
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

let screenUnlockedObserver = DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screenIsUnlocked"),
    object: nil,
    queue: .main
) { _ in
    log("Screen unlocked.")
    wakeBlock(Notification(name: NSNotification.Name("com.apple.screenIsUnlocked")))
}

let sessionActiveObserver = NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.sessionDidBecomeActiveNotification,
    object: nil,
    queue: .main,
    using: wakeBlock
)

// MARK: - Normal Backup Sync

let backupTimer = Timer(timeInterval: normalBackupInterval, repeats: true) { _ in
    enforceLED(force: true)
}

RunLoop.main.add(backupTimer, forMode: .common)

// MARK: - Run

log("MyLEDIsSmarterThanMe daemon started.")
RunLoop.main.run()
