import SwiftUI
import AppKit
import AudioToolbox
import Combine

/// Michael: The Typing Buddy from Needle.
/// Monitors typing speed (WPM) in real time and plays mechanical keyboard sounds.
/// Privacy-first: only records timestamps to count speed; NEVER reads or logs typed characters.
@MainActor
final class TypingBuddy: ObservableObject {
    static let shared = TypingBuddy()

    @Published var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "typingBuddyEnabled")
            updateMonitoring()
        }
    }
    @Published var soundpack: String = "mechanical" {
        didSet { UserDefaults.standard.set(soundpack, forKey: "typingSoundpack") }
    }
    @Published var playSounds: Bool = true {
        didSet { UserDefaults.standard.set(playSounds, forKey: "typingSoundsEnabled") }
    }
    @Published var wpm: Int = 0
    @Published var totalKeystrokes: Int = 0
    @Published var lastKeyTime: Date = Date()
    @Published var isKeyPressed: Bool = false

    private var keyTimestamps: [Double] = []
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var decayTimer: Timer?

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "typingBuddyEnabled")
        self.soundpack = UserDefaults.standard.string(forKey: "typingSoundpack") ?? "mechanical"
        self.playSounds = UserDefaults.standard.object(forKey: "typingSoundsEnabled") as? Bool ?? true
        updateMonitoring()

        decayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recalculateWPM()
            }
        }
    }

    private func updateMonitoring() {
        if isEnabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            Task { @MainActor in
                self?.handleKeypress()
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handleKeypress()
            }
            return event
        }
    }

    private func stopMonitoring() {
        if let g = globalMonitor { NSEvent.removeMonitor(g); globalMonitor = nil }
        if let l = localMonitor { NSEvent.removeMonitor(l); localMonitor = nil }
        wpm = 0
    }

    private func handleKeypress() {
        let now = Date().timeIntervalSinceReferenceDate
        keyTimestamps.append(now)
        totalKeystrokes += 1
        lastKeyTime = Date()
        isKeyPressed = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.isKeyPressed = false
        }

        if playSounds {
            playSound()
        }
        recalculateWPM()
    }

    private func recalculateWPM() {
        let now = Date().timeIntervalSinceReferenceDate
        keyTimestamps = keyTimestamps.filter { now - $0 <= 5.0 }
        // 5 keystrokes ≈ 1 word. WPM = (keystrokes / 5) * (60 / timeWindow)
        let count = keyTimestamps.count
        let calculated = Int(Double(count) / 5.0 * 12.0)
        withAnimation(.easeInOut(duration: 0.2)) {
            self.wpm = calculated
        }
    }

    private func playSound() {
        // High-precision system sound click effects
        switch soundpack {
        case "retro":
            // Heavy vintage terminal click
            AudioServicesPlaySystemSound(1105)
        case "typewriter":
            // Mechanical typewriter striker
            AudioServicesPlaySystemSound(1104)
        default:
            // Crisp mechanical tactile switch
            AudioServicesPlaySystemSound(1123)
        }
    }
}

/// Floating keycap widget for Michael
struct MichaelKeycapView: View {
    @ObservedObject var buddy = TypingBuddy.shared
    var size: CGFloat = 64

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Keycap Base
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(Color(white: 0.18))
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 3)

                // Keycap Top Surface with spring bounce
                RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                    .fill(LinearGradient(colors: [Color(white: 0.35), Color(white: 0.22)], startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.82, height: size * 0.82)
                    .offset(y: buddy.isKeyPressed ? 3 : -2)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            .offset(y: buddy.isKeyPressed ? 3 : -2)
                    )

                // Keycap Legend (Michael)
                VStack(spacing: 1) {
                    Text("M")
                        .font(.system(size: size * 0.32, weight: .black, design: .rounded))
                        .foregroundStyle(buddy.isKeyPressed ? Color.pink : Color.white)
                    Text("\(buddy.wpm) WPM")
                        .font(.system(size: size * 0.14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .offset(y: buddy.isKeyPressed ? 3 : -2)
            }
            .animation(.spring(response: 0.15, dampingFraction: 0.5), value: buddy.isKeyPressed)

            Text("Michael")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}
