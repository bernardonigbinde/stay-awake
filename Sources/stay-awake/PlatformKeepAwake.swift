import Foundation

protocol PlatformKeepAwake {
    mutating func preventSleep() -> Bool
    func nudge()
    mutating func releaseSleep()
}

func makeKeepAwake() -> PlatformKeepAwake? {
#if os(macOS)
    return MacKeepAwake()
#elseif os(Windows)
    return WindowsKeepAwake()
#elseif os(Linux)
    return LinuxKeepAwake()
#else
    return nil
#endif
}

#if os(macOS)
import IOKit.pwr_mgt
import CoreGraphics

struct MacKeepAwake: PlatformKeepAwake {
    private var systemAssertion: IOPMAssertionID = 0
    private var displayAssertion: IOPMAssertionID = 0

    mutating func preventSleep() -> Bool {
        let reason = "stay-awake keeping the machine active" as CFString
        let system = IOPMAssertionCreateWithName(
            kIOPMAssertPreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &systemAssertion) == kIOReturnSuccess
        let display = IOPMAssertionCreateWithName(
            kIOPMAssertPreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &displayAssertion) == kIOReturnSuccess
        return system || display
    }

    func nudge() {
        guard let current = CGEvent(source: nil)?.location else { return }
        let shifted = CGPoint(x: current.x + 1, y: current.y)
        CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                mouseCursorPosition: shifted, mouseButton: .left)?.post(tap: .cghidEventTap)
        CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                mouseCursorPosition: current, mouseButton: .left)?.post(tap: .cghidEventTap)
    }

    mutating func releaseSleep() {
        if systemAssertion != 0 {
            IOPMAssertionRelease(systemAssertion)
            systemAssertion = 0
        }
        if displayAssertion != 0 {
            IOPMAssertionRelease(displayAssertion)
            displayAssertion = 0
        }
    }
}
#endif

#if os(Windows)
import WinSDK

struct WindowsKeepAwake: PlatformKeepAwake {
    mutating func preventSleep() -> Bool {
        let flags = ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
        return SetThreadExecutionState(flags) != 0
    }

    func nudge() {
        var input = INPUT()
        input.type = DWORD(INPUT_MOUSE)
        input.mi = MOUSEINPUT(dx: 0, dy: 0, mouseData: 0,
                              dwFlags: DWORD(MOUSEEVENTF_MOVE), time: 0, dwExtraInfo: 0)
        SendInput(1, &input, Int32(MemoryLayout<INPUT>.size))
    }

    mutating func releaseSleep() {
        _ = SetThreadExecutionState(ES_CONTINUOUS)
    }
}
#endif

#if os(Linux)
import CX11

struct LinuxKeepAwake: PlatformKeepAwake {
    private var inhibitor: Process?

    mutating func preventSleep() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["systemd-inhibit",
                             "--what=idle:sleep",
                             "--why=stay-awake keeping the machine active",
                             "--mode=block",
                             "sleep", "infinity"]
        do {
            try process.run()
            inhibitor = process
            warnIfNoIdleReset()
            return true
        } catch {
            return false
        }
    }

    private func warnIfNoIdleReset() {
        let env = ProcessInfo.processInfo.environment
        let onWayland = env["XDG_SESSION_TYPE"] == "wayland" || env["WAYLAND_DISPLAY"] != nil
        let noDisplay = (env["DISPLAY"] ?? "").isEmpty
        guard onWayland || noDisplay else { return }
        let note = "warning: no X11 session, so the presence nudge is off. " +
                   "sleep is still blocked via systemd-inhibit.\n"
        FileHandle.standardError.write(Data(note.utf8))
    }

    func nudge() {
        guard let display = XOpenDisplay(nil) else { return }
        XTestFakeRelativeMotionEvent(display, 1, 0, 0)
        XTestFakeRelativeMotionEvent(display, -1, 0, 0)
        XFlush(display)
        XCloseDisplay(display)
    }

    mutating func releaseSleep() {
        inhibitor?.terminate()
        inhibitor = nil
    }
}
#endif
