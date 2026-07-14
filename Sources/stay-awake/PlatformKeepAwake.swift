import Foundation

protocol PlatformKeepAwake {
    mutating func preventSleep() -> Bool
    mutating func releaseSleep()
}

func makeKeepAwake() -> PlatformKeepAwake? {
#if os(macOS)
    return MacKeepAwake()
#else
    return nil
#endif
}

#if os(macOS)
import IOKit.pwr_mgt

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
