import Foundation

let programName = "stay-awake"
let defaultDuration = "1h"
let nudgeInterval: TimeInterval = 120

var stopRequested: sig_atomic_t = 0

func handleStop(_ signal: Int32) {
    stopRequested = 1
}

func writeCountdown(_ remaining: TimeInterval) {
    let total = max(0, Int(remaining))
    print(String(format: "\ractive - %02d:%02d:%02d remaining ",
                 total / 3600, (total % 3600) / 60, total % 60),
          terminator: "")
}

struct Duration {
    let seconds: Double
    let label: String
}

func parseDuration(_ raw: String) -> Duration? {
    guard let unit = raw.last else { return nil }
    let numberPart = String(raw.dropLast())
    guard let value = Double(numberPart), value > 0 else { return nil }
    switch unit {
    case "h", "H": return Duration(seconds: value * 3600, label: raw)
    case "m", "M": return Duration(seconds: value * 60, label: raw)
    default: return nil
    }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func printUsage() {
    print("\(programName) - keep this machine awake and active")
    print("usage: \(programName) <duration>")
    print("  duration: <n>h or <n>m, e.g. 2h, 45m (default \(defaultDuration))")
}

let arguments = CommandLine.arguments
if arguments.contains("-h") || arguments.contains("--help") {
    printUsage()
    exit(0)
}

let durationArg = arguments.count > 1 ? arguments[1] : defaultDuration
guard let duration = parseDuration(durationArg) else {
    fail("invalid duration: '\(durationArg)' (use e.g. 90m or 2h)")
}

guard var keeper = makeKeepAwake() else {
    fail("no keep-awake backend for this platform yet")
}

guard keeper.preventSleep() else {
    fail("could not acquire a sleep-prevention assertion")
}

print("staying awake for \(duration.label). press ctrl-c to stop.")

signal(SIGINT, handleStop)
signal(SIGTERM, handleStop)

let deadline = Date().addingTimeInterval(duration.seconds)
keeper.nudge()
var lastNudge = Date()

while stopRequested == 0 && deadline.timeIntervalSinceNow > 0 {
    if Date().timeIntervalSince(lastNudge) >= nudgeInterval {
        keeper.nudge()
        lastNudge = Date()
    }
    writeCountdown(deadline.timeIntervalSinceNow)
    Thread.sleep(forTimeInterval: 1)
}

print("")
keeper.releaseSleep()
print(stopRequested == 0 ? "done." : "stopped.")
