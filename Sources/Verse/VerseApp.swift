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
    var bag = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let d = UserDefaults.standard
        if d.object(forKey: K.shape) == nil {
            d.set((NSScreen.main?.safeAreaInsets.top ?? 0) > 0 ? "classic" : "floating", forKey: K.shape)
        }
        d.set(false, forKey: K.expanded)

        NowPlaying.shared.start()
        Weather.shared.start()
        NowPlaying.shared.$track.removeDuplicates().sink { LyricsStore.shared.load($0) }.store(in: &bag)

        panel = makePanel(RootView(), level: .statusBar)
        NotificationCenter.default.addObserver(self, selector: #selector(layout),
                                               name: UserDefaults.didChangeNotification, object: nil)
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
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        let host = NSHostingView(rootView: view)
        host.sizingOptions = []
        p.contentView = host
        return p
    }

    @objc func layout() {
        guard let screen = NSScreen.main else { return }
        let d = UserDefaults.standard
        let mode = d.string(forKey: K.mode) ?? "island"
        let expanded = d.bool(forKey: K.expanded)
        let shape = d.string(forKey: K.shape) ?? "classic"
        let hasCity = !(d.string(forKey: K.city) ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        let sig = "\(mode)|\(expanded)|\(shape)|\(hasCity)"
        if sig != mainSig {
            mainSig = sig
            applyMain(screen, mode: mode, expanded: expanded, shape: shape, hasCity: hasCity)
        }

        if d.bool(forKey: K.glow) {
            if glowPanel == nil {
                glowPanel = makePanel(EdgeGlowView(), level: .floating, ignoresMouse: true)
                glowPanel?.setFrame(screen.frame, display: true)
            }
            glowPanel?.orderFrontRegardless()
        } else {
            glowPanel?.orderOut(nil)
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
        case "desktop":
            frame = f
            level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        default:
            let w: CGFloat = expanded ? 460 : 420
            let h: CGFloat = expanded ? (hasCity ? 332 : 284) : (shape == "classic" ? 62 : 56)
            let gap: CGFloat = shape == "classic" ? 0 : 10
            frame = NSRect(x: f.midX - w / 2, y: f.maxY - h - gap, width: w, height: h)
        }
        panel.ignoresMouseEvents = (mode == "desktop")
        panel.isMovableByWindowBackground = (mode == "lyrics")
        panel.level = level
        panel.setFrame(frame, display: true, animate: mode == "island")
        panel.orderFrontRegardless()
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 580),
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

struct MenuView: View {
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared
    @AppStorage(K.mode) private var mode = "island"
    @AppStorage(K.theme) private var theme = LyricTheme.bigWord.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CoverView(art: np.artwork, size: 40)
                VStack(alignment: .leading) {
                    Text(np.track?.title ?? "Nothing playing").font(.headline).lineLimit(1)
                    Text(np.track?.artist ?? "Open Spotify or Music").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Picker("View", selection: $mode) {
                Text("Island (notch)").tag("island")
                Text("Lyrics window").tag("lyrics")
                Text("Full screen").tag("fullscreen")
                Text("Desktop").tag("desktop")
                Text("Hidden").tag("hidden")
            }
            Picker("Theme", selection: $theme) {
                ForEach(LyricTheme.allCases) { Text($0.title).tag($0.rawValue) }
            }
            HStack {
                Text("Sync (this song)")
                Spacer()
                Button("−1") { lyrics.nudge(-1) }
                Button("−.1") { lyrics.nudge(-0.1) }
                Text(String(format: "%+.1fs", lyrics.offset)).monospacedDigit().frame(width: 52)
                Button("+.1") { lyrics.nudge(0.1) }
                Button("+1") { lyrics.nudge(1) }
                Button("Reset") { lyrics.offset = 0 }
            }
            Divider()
            Button("Copy lyric card") { Sharing.copyCard() }
            Button("Set wallpaper from album colours") { Sharing.setWallpaper() }
            Button("Settings…") { NotificationCenter.default.post(name: .verseSettings, object: nil) }
            Button("Quit Verse") { NSApp.terminate(nil) }
        }
        .padding(14).frame(width: 330)
    }
}
