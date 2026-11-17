import SwiftUI
import Combine

@main
struct VerseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        MenuBarExtra("Verse", systemImage: "music.note.list") { MenuView() }
            .menuBarExtraStyle(.window)
    }
}

struct RootView: View {
    @AppStorage(K.mode) private var mode = "island"
    var body: some View {
        switch mode {
        case "island": IslandView()
        case "lyrics": LyricsContainer(rounded: true)
        default: LyricsContainer(rounded: false)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var glowPanel: NSPanel?
    var recordPanel: NSPanel?
    var settingsWindow: NSWindow?
    var mainSig = ""
    var layoutPending = false
    var bag = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if let icon = Bundle.main.path(forResource: "AppIcon", ofType: "icns").flatMap({ NSImage(contentsOfFile: $0) }) ??
                      NSImage(contentsOfFile: "Resources/AppIcon.icns") ??
                      NSImage(contentsOfFile: "Resources/AppIcon-1024.png") {
            NSApp.applicationIconImage = icon
        }
        let d = UserDefaults.standard
        if d.object(forKey: K.shape) == nil {
            d.set((NSScreen.main?.safeAreaInsets.top ?? 0) > 0 ? "classic" : "floating", forKey: K.shape)
        }
        d.set(false, forKey: K.expanded)

        NowPlaying.shared.start()
        Weather.shared.start()
        NowPlaying.shared.$track.removeDuplicates().sink { LyricsStore.shared.load($0) }.store(in: &bag)

        // Initialize background managers and hardware monitors
        ScreenWakeManager.shared.evaluate()
        _ = LockScreenController.shared
        _ = TypingBuddy.shared
        _ = WallpaperManager.shared
        _ = AirPodsMonitor.shared
        UpdateManager.shared.startAutoCheck()

        panel = makePanel(RootView(), level: .statusBar)
        NotificationCenter.default.addObserver(self, selector: #selector(scheduleLayout),
                                               name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scheduleLayout),
                                               name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(scheduleLayout),
                                                          name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openSettings),
                                               name: .verseSettings, object: nil)
        layout()
    }

    func applicationWillTerminate(_ n: Notification) { Diary.shared.save() }

    func makePanel<V: View>(_ view: V, level: NSWindow.Level, ignoresMouse: Bool = false) -> NSPanel {
        let p = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = level
        p.ignoresMouseEvents = ignoresMouse
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let host = NSHostingView(rootView: view)
        host.sizingOptions = []
        p.contentView = host
        return p
    }

    /// UserDefaults changes can arrive in the middle of a SwiftUI update; re-layout on the next turn instead.
    @objc func scheduleLayout() {
        guard !layoutPending else { return }
        layoutPending = true
        Task { @MainActor [weak self] in
            self?.layoutPending = false
            self?.layout()
        }
    }

    @objc func layout() {
        guard let screen = NSScreen.main else { return }
        let d = UserDefaults.standard
        let mode = d.string(forKey: K.mode) ?? "island"
        let expanded = d.bool(forKey: K.expanded)
        let shape = d.string(forKey: K.shape) ?? "classic"
        let hasCity = !(d.string(forKey: K.city) ?? "").trimmingCharacters(in: .whitespaces).isEmpty

        if d.bool(forKey: K.glow) {
            let glowLevel = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) - 1)
            if glowPanel == nil {
                glowPanel = makePanel(EdgeGlowView(), level: glowLevel, ignoresMouse: true)
            }
            glowPanel?.level = glowLevel
            glowPanel?.setFrame(screen.frame, display: true)
            glowPanel?.orderFrontRegardless()
        } else {
            glowPanel?.orderOut(nil)
        }

        if d.bool(forKey: K.glow) && (d.string(forKey: K.glowSync) ?? "audio") == "audio" {
            AudioReactor.shared.start()
        } else {
            AudioReactor.shared.stop()
        }

        let sig = "\(mode)|\(expanded)|\(shape)|\(hasCity)|\(screen.frame)"
        if sig != mainSig {
            mainSig = sig
            applyMain(screen, mode: mode, expanded: expanded, shape: shape, hasCity: hasCity)
        } else if d.bool(forKey: K.glow) {
            glowPanel?.orderFrontRegardless()
        }

        if d.bool(forKey: K.record) {
            if recordPanel == nil {
                let p = makePanel(RecordWidget(), level: NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1))
                p.isMovableByWindowBackground = true
                let v = screen.visibleFrame
                p.setFrame(NSRect(x: v.minX + 40, y: v.minY + 40, width: 320, height: 380), display: true)
                recordPanel = p
            }
            recordPanel?.orderFrontRegardless()
        } else {
            recordPanel?.orderOut(nil)
        }
        Weather.shared.refreshIfNeeded()
    }

    func applyMain(_ screen: NSScreen, mode: String, expanded: Bool, shape: String, hasCity: Bool) {
        if mode == "hidden" { panel.orderOut(nil); return }
        let f = screen.frame
        var frame: NSRect
        var level = NSWindow.Level.statusBar
        switch mode {
        case "lyrics":
            frame = NSRect(x: f.midX - 380, y: f.midY - 220, width: 760, height: 440)
            level = .floating
        case "fullscreen":
            frame = f
            level = .floating
        case "desktop":
            frame = f
            level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        default:
            let nh = NotchInfo.height, nw = NotchInfo.width
            let extra: CGFloat = hasCity ? 48 : 0
            let w: CGFloat, h: CGFloat
            if shape == "classic" {
                w = expanded ? max(480, nw + 260) : max(nw + 190, 340)
                h = expanded ? nh + 250 + extra : nh + 28
            } else {
                w = expanded ? 460 : 400
                h = expanded ? 268 + extra : 56
            }
            let gap: CGFloat = shape == "classic" ? 0 : 10
            frame = NSRect(x: f.midX - w / 2, y: f.maxY - h - gap, width: w, height: h)
        }
        panel.ignoresMouseEvents = (mode == "desktop")
        panel.isMovableByWindowBackground = (mode == "lyrics")
        panel.level = level
        panel.setFrame(frame, display: true, animate: mode == "island")
        panel.orderFrontRegardless()

        if UserDefaults.standard.bool(forKey: K.glow) {
            glowPanel?.orderFrontRegardless()
        }
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 780, height: 600),
                             styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            w.title = "Verse Settings"
            w.contentView = NSHostingView(rootView: SettingsView())
            w.isReleasedWhenClosed = false
            w.center()
            settingsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}

