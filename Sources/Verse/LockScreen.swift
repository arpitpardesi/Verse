import SwiftUI
import AppKit
import Combine

/// Lock Screen integration matching Needle:
/// Displays an interactive record player, artwork, or live lyrics under the macOS lock screen clock.
@MainActor
final class LockScreenController: ObservableObject {
    static let shared = LockScreenController()

    @Published var isLocked: Bool = false
    @Published var isPreviewing: Bool = false
    @Published var mode: LockDisplayMode = .record

    private var lockPanel: NSPanel?
    private var bag = Set<AnyCancellable>()

    enum LockDisplayMode: String, CaseIterable {
        case record = "turntable"
        case artwork = "artwork"
        case lyrics = "lyrics"

        var title: String {
            switch self {
            case .record: return "Vinyl"
            case .artwork: return "Artwork"
            case .lyrics: return "Lyrics"
            }
        }

        var icon: String {
            switch self {
            case .record: return "record.circle"
            case .artwork: return "photo"
            case .lyrics: return "quote.bubble"
            }
        }
    }

    static var isSystemLocked: Bool {
        guard let dict = CGSessionCopyCurrentDictionary() as? [String: Any] else { return false }
        if let b = dict["CGSSessionScreenIsLocked"] as? Bool {
            return b
        }
        if let num = dict["CGSSessionScreenIsLocked"] as? NSNumber {
            return num.boolValue
        }
        if let num = dict["CGSSessionScreenIsLocked"] as? Int {
            return num != 0
        }
        return false
    }

    private var lockTimer: Timer?

    init() {
        let savedStyle = UserDefaults.standard.string(forKey: "lockScreenStyle") ?? "turntable"
        self.mode = LockDisplayMode(rawValue: savedStyle) ?? .record
        self.isLocked = Self.isSystemLocked

        setupSystemObservers()

        // React to playback changes
        NowPlaying.shared.$track
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updatePanelVisibility() }
            .store(in: &bag)

        NowPlaying.shared.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updatePanelVisibility() }
            .store(in: &bag)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updatePanelVisibility() }
            .store(in: &bag)

        if isLocked {
            startLockTimer()
        }
    }

    private func setupSystemObservers() {
        let dnc = DistributedNotificationCenter.default()

        // 1. Distributed notifications with suspensionBehavior: .deliverImmediately
        dnc.addObserver(self, selector: #selector(handleScreenLocked),
                        name: NSNotification.Name("com.apple.screenIsLocked"), object: nil,
                        suspensionBehavior: .deliverImmediately)
        dnc.addObserver(self, selector: #selector(handleScreenUnlocked),
                        name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil,
                        suspensionBehavior: .deliverImmediately)

        // 2. Screensaver triggers
        dnc.addObserver(self, selector: #selector(handleScreenLocked),
                        name: NSNotification.Name("com.apple.screensaver.didstart"), object: nil,
                        suspensionBehavior: .deliverImmediately)
        dnc.addObserver(self, selector: #selector(handleScreenUnlocked),
                        name: NSNotification.Name("com.apple.screensaver.didstop"), object: nil,
                        suspensionBehavior: .deliverImmediately)

        // 3. Workspace Console Session changes (Fires when screen locks / switches to loginwindow)
        let wnc = NSWorkspace.shared.notificationCenter
        wnc.addObserver(self, selector: #selector(handleScreenLocked),
                        name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        wnc.addObserver(self, selector: #selector(handleSessionActive),
                        name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        wnc.addObserver(self, selector: #selector(handleScreenSleep),
                        name: NSWorkspace.screensDidSleepNotification, object: nil)
        wnc.addObserver(self, selector: #selector(handleScreenWake),
                        name: NSWorkspace.screensDidWakeNotification, object: nil)

        // 4. Darwin Notification Center (Low-level C notification dispatch)
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let mySelf = Unmanaged<LockScreenController>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    mySelf.handleScreenLocked()
                }
            },
            "com.apple.screenIsLocked" as CFString,
            nil,
            .deliverImmediately
        )

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let mySelf = Unmanaged<LockScreenController>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    mySelf.handleScreenUnlocked()
                }
            },
            "com.apple.screenIsUnlocked" as CFString,
            nil,
            .deliverImmediately
        )
    }

    @objc func handleScreenLocked() {
        isLocked = true
        updatePanelVisibility()
        // Re-assert front as macOS loginwindow transitions into view
        for delay in [0.1, 0.3, 0.6, 1.0, 1.8, 2.5] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.isLocked else { return }
                self.updatePanelVisibility()
                self.lockPanel?.orderFrontRegardless()
            }
        }
        startLockTimer()
    }

    @objc func handleSessionActive() {
        if isLocked {
            updatePanelVisibility()
            lockPanel?.orderFrontRegardless()
        }
    }

    @objc func handleScreenSleep() {
        // Display sleep during lock - maintain state
    }

    @objc func handleScreenWake() {
        if isLocked {
            updatePanelVisibility()
            for delay in [0.1, 0.4, 0.8] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self, self.isLocked else { return }
                    self.updatePanelVisibility()
                    self.lockPanel?.orderFrontRegardless()
                }
            }
        }
    }

    @objc func handleScreenUnlocked() {
        isLocked = false
        stopLockTimer()
        if !isPreviewing {
            lockPanel?.orderOut(nil)
        }
    }

    private func startLockTimer() {
        lockTimer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isLocked else { return }
                // Re-assert front layer above loginwindow while screen is locked
                self.lockPanel?.orderFrontRegardless()
            }
        }
        t.tolerance = 0.5
        lockTimer = t
    }

    private func stopLockTimer() {
        lockTimer?.invalidate()
        lockTimer = nil
    }

    func lockScreenImmediately() {
        // Try SACLockScreenImmediate dynamically from login.framework
        if let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY) {
            defer { dlclose(handle) }
            typealias LockFunc = @convention(c) () -> Int32
            if let sym = dlsym(handle, "SACLockScreenImmediate") {
                let fn = unsafeBitCast(sym, to: LockFunc.self)
                _ = fn()
                handleScreenLocked()
                return
            }
        }
        // Fallback: keystroke Command-Control-Q via System Events
        let script = "tell application \"System Events\" to keystroke \"q\" using {command down, control down}"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
        handleScreenLocked()
    }

    func togglePreview() {
        isPreviewing.toggle()
        updatePanelVisibility()
    }

    func updatePanelVisibility() {
        let enabled = UserDefaults.standard.object(forKey: "lockScreenEnabled") as? Bool ?? true
        let shouldShow = enabled && (isLocked || isPreviewing)

        guard shouldShow else {
            lockPanel?.orderOut(nil)
            return
        }

        guard let screen = NSScreen.screens.first ?? NSScreen.main else { return }

        let shieldLevel = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))

        if lockPanel == nil {
            let p = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.level = shieldLevel
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            p.hidesOnDeactivate = false
            p.canHide = false
            p.isReleasedWhenClosed = false
            p.isMovableByWindowBackground = true
            p.isExcludedFromWindowsMenu = true

            let host = NSHostingView(rootView: LockScreenPlayerView())
            p.contentView = host
            lockPanel = p
        }

        lockPanel?.level = shieldLevel

        let sf = screen.frame
        let w: CGFloat = 390
        let h: CGFloat = 490
        // Center below the lock screen clock (approx 36% below the top edge)
        let y = max(60, sf.midY - h / 2 - 35)
        let frame = NSRect(x: sf.midX - w / 2, y: y, width: w, height: h)

        lockPanel?.setFrame(frame, display: true)
        lockPanel?.orderFrontRegardless()
    }

    func cycleMode() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            switch mode {
            case .record: mode = .artwork
            case .artwork: mode = .lyrics
            case .lyrics: mode = .record
            }
        }
    }
}

/// Interactive Lock Screen view: clicking flips between Vinyl, Artwork, and Synced Lyrics.
struct LockScreenPlayerView: View {
    @ObservedObject var lock = LockScreenController.shared
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared

    var tint: Color { np.colors.first ?? .pink }

    var body: some View {
        VStack(spacing: 12) {
            // Top Bar: Preview pill & Mode Switcher
            HStack {
                if lock.isPreviewing {
                    HStack(spacing: 6) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                        Text("Lock Screen Preview")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                }

                Spacer()

                // Mode picker capsules
                HStack(spacing: 4) {
                    ForEach(LockScreenController.LockDisplayMode.allCases, id: \.self) { m in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                                lock.mode = m
                            }
                        } label: {
                            Image(systemName: m.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(lock.mode == m ? .white : .white.opacity(0.5))
                                .frame(width: 28, height: 28)
                                .background(lock.mode == m ? tint.opacity(0.75) : Color.white.opacity(0.06), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.8))

                if lock.isPreviewing {
                    Button {
                        lock.togglePreview()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
            }
            .frame(width: 320)

            // Center Interactive Content (Vinyl, Art, or Lyrics)
            ZStack {
                switch lock.mode {
                case .record:
                    VStack(spacing: 10) {
                        RecordView(size: 240)
                            .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
                        Text("Tap to view artwork")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .transition(.scale(scale: 0.94).combined(with: .opacity))

                case .artwork:
                    VStack(spacing: 10) {
                        CoverView(art: np.artwork, size: 240, radius: 24)
                            .shadow(color: tint.opacity(0.4), radius: 24, y: 8)
                            .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
                        Text("Tap to view synced lyrics")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .transition(.scale(scale: 0.94).combined(with: .opacity))

                case .lyrics:
                    VStack(spacing: 10) {
                        TimelineView(.periodic(from: .now, by: np.isPlaying ? 0.15 : 2.0)) { ctx in
                            let pos = np.position(at: ctx.date) + lyrics.totalOffset
                            if case .synced(let lines) = lyrics.state {
                                let idx = lineIndex(lines, pos)
                                VStack(spacing: 10) {
                                    if idx >= 0, idx < lines.count {
                                        Text(lines[idx].text)
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.center)
                                            .shadow(color: tint.opacity(0.7), radius: 10)
                                    }
                                    if idx + 1 < lines.count {
                                        Text(lines[idx + 1].text)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.4))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(24)
                                .frame(width: 310, height: 240)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 34))
                                        .foregroundStyle(tint)
                                    Text("Enjoying the music...")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                .frame(width: 310, height: 240)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                            }
                        }
                        Text("Tap to view vinyl turntable")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                lock.cycleMode()
            }

            // Track details
            VStack(spacing: 3) {
                Text(np.track?.title ?? "Nothing Playing")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(np.track?.artist ?? "Open Spotify or Apple Music")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
            .shadow(color: .black.opacity(0.7), radius: 6)

            // Playback controls
            HStack(spacing: 24) {
                Button { np.command("previous track") } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                Button { np.command("playpause") } label: {
                    Image(systemName: np.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(tint.opacity(0.85), in: Circle())
                        .shadow(color: tint.opacity(0.5), radius: 8)
                }
                .buttonStyle(.plain)

                Button { np.command("next track") } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
        }
        .padding(20)
    }
}
