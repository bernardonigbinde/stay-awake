import Foundation

let programName = "stay-awake"
let version = "0.1.0"
let defaultDuration = "1h"

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
    print("  -v, --version   print version")
    print("  -h, --help      print this help")
}

let arguments = CommandLine.arguments
if arguments.contains("-h") || arguments.contains("--help") {
    printUsage()
    exit(0)
}

if arguments.contains("-v") || arguments.contains("--version") {
    print("\(programName) \(version)")
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

Runner().run(keeper: &keeper, duration: duration)
