import SwiftUI
import AppKit
import IOKit.ps

/// System power, battery state, and Low Power Mode manager for macOS.
/// Ensures Verse consumes minimal energy on MacBooks running on battery.
@MainActor
final class PowerOptimizer: ObservableObject {
    static let shared = PowerOptimizer()

    @Published var isLowPowerMode: Bool = false
    @Published var isOnBattery: Bool = false
    @Published var batteryLevel: Int = 100

    private var observer: NSObjectProtocol?
    private var pollTimer: Timer?

    init() {
        self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        updatePowerState()

        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
                self?.updatePowerState()
            }
        }

        // Low-frequency relaxed check every 60s
        pollTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePowerState()
            }
        }
        pollTimer?.tolerance = 15.0
    }

    func updatePowerState() {
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            isOnBattery = false
            return
        }

        var onBattery = false
        var currentLevel = 100

        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            if let state = desc[kIOPSPowerSourceStateKey] as? String, state == kIOPSBatteryPowerValue {
                onBattery = true
            }

            if let cap = desc[kIOPSCurrentCapacityKey] as? Int,
               let maxCap = desc[kIOPSMaxCapacityKey] as? Int, maxCap > 0 {
                currentLevel = min(100, max(0, Int((Double(cap) / Double(maxCap)) * 100)))
            }
        }

        self.isOnBattery = onBattery
        self.batteryLevel = currentLevel
    }

    /// Optimal frame interval for animations based on power state
    var animationInterval: Double {
        if isLowPowerMode {
            return 1.0 / 24.0 // Conserve GPU on Low Power Mode
        } else if isOnBattery {
            return 1.0 / 30.0 // Smooth 30 FPS on battery
        } else {
            return 1.0 / 60.0 // Full 60 FPS on AC power
        }
    }
}
