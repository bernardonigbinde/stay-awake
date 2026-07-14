import Foundation

let programName = "stay-awake"

func printUsage() {
    print("\(programName) - keep this machine awake and active")
    print("usage: \(programName) <duration>")
    print("  duration: <n>h or <n>m, e.g. 2h, 45m (default 1h)")
}

printUsage()
