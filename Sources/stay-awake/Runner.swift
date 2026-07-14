import Foundation

var stopRequested: sig_atomic_t = 0

func handleStop(_ signal: Int32) {
    stopRequested = 1
}

struct Runner {
    let nudgeInterval: TimeInterval = 120

    func run(keeper: inout PlatformKeepAwake, duration: Duration) {
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
    }

    private func writeCountdown(_ remaining: TimeInterval) {
        let total = max(0, Int(remaining))
        print(String(format: "\ractive - %02d:%02d:%02d remaining ",
                     total / 3600, (total % 3600) / 60, total % 60),
              terminator: "")
        fflush(stdout)
    }
}
