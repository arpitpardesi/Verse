import Foundation
import IOKit.pwr_mgt
import Combine

/// Prevents the display from sleeping while lyrics are actively playing (matches Needle's screen-wake feature).
@MainActor
final class ScreenWakeManager: ObservableObject {
    static let shared = ScreenWakeManager()
    private var assertionID: IOPMAssertionID = 0
    private var hasAssertion = false
    private var bag = Set<AnyCancellable>()

    init() {
        NowPlaying.shared.$isPlaying
            .sink { [weak self] playing in
                self?.evaluate(playing: playing)
            }
            .store(in: &bag)
    }

    func evaluate(playing: Bool? = nil) {
        let isPlaying = playing ?? NowPlaying.shared.isPlaying
        let enabled = UserDefaults.standard.object(forKey: "keepScreenAwake") as? Bool ?? true
        let power = PowerOptimizer.shared
        // Battery safeguard: Don't force display awake if in Low Power Mode or critically low battery (<20%)
        let batteryAllows = !power.isLowPowerMode && !(power.isOnBattery && power.batteryLevel <= 20)

        if isPlaying && enabled && batteryAllows {
            acquire()
        } else {
            release()
        }
    }

    private func acquire() {
        guard !hasAssertion else { return }
        let reason = "Verse is playing music with live lyrics" as CFString
        let res = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if res == kIOReturnSuccess {
            hasAssertion = true
        }
    }

    private func release() {
        guard hasAssertion else { return }
        IOPMAssertionRelease(assertionID)
        hasAssertion = false
        assertionID = 0
    }
}
