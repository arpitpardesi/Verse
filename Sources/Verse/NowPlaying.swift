import Foundation
import AppKit
import SwiftUI

@MainActor
final class NowPlaying: ObservableObject {
    static let shared = NowPlaying()
    @Published var track: Track?
    @Published var isPlaying = false
    @Published var artwork: NSImage?
    @Published var colors: [Color] = [.purple, .blue, .pink]
    @Published var volume = 50.0

    private var basePosition = 0.0
    private var baseDate = Date()
    private var lastPoll = Date()
    private var timer: Timer?
    private var artTask: Task<Void, Never>?
    private static let artCache = NSCache<NSString, NSImage>()

    func position(at date: Date = Date()) -> Double {
        isPlaying ? basePosition + date.timeIntervalSince(baseDate) : basePosition
    }

    func start() {
        setupSystemObservers()
        rescheduleTimer()
        poll()
    }

    private func setupSystemObservers() {
        let dnc = DistributedNotificationCenter.default()
        // Spotify playback change notification
        dnc.addObserver(self, selector: #selector(handlePlayerNotification),
                        name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"), object: nil,
                        suspensionBehavior: .deliverImmediately)
        // Apple Music playback change notification
        dnc.addObserver(self, selector: #selector(handlePlayerNotification),
                        name: NSNotification.Name("com.apple.Music.playerInfo"), object: nil,
                        suspensionBehavior: .deliverImmediately)

        // Display sleep / wake to eliminate wasted polling
        let wnc = NSWorkspace.shared.notificationCenter
        wnc.addObserver(self, selector: #selector(handleScreensDidSleep),
                        name: NSWorkspace.screensDidSleepNotification, object: nil)
        wnc.addObserver(self, selector: #selector(handleScreensDidWake),
                        name: NSWorkspace.screensDidWakeNotification, object: nil)
    }

    @objc private func handlePlayerNotification() {
        Task { @MainActor in
            self.poll()
        }
    }

    @objc private func handleScreensDidSleep() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func handleScreensDidWake() {
        rescheduleTimer()
        poll()
    }

    private func rescheduleTimer() {
        timer?.invalidate()
        let interval: TimeInterval = isPlaying ? 1.5 : 4.0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        timer?.tolerance = isPlaying ? 0.3 : 1.0
    }

    private let spotifyScript = """
    tell application "Spotify"
      if player state is stopped then return "stopped"
      set t to current track
      return (player state as text) & "||" & (name of t) & "||" & (artist of t) & "||" & (album of t) & "||" & (duration of t) & "||" & (player position) & "||" & (artwork url of t) & "||" & (sound volume)
    end tell
    """
    private let musicScript = """
    tell application "Music"
      if player state is stopped then return "stopped"
      set t to current track
      return (player state as text) & "||" & (name of t) & "||" & (artist of t) & "||" & (album of t) & "||" & (duration of t) & "||" & (player position) & "||" & "" & "||" & (sound volume)
    end tell
    """

    private func running(_ bundle: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundle).isEmpty
    }

    private func run(_ src: String) -> String? {
        var err: NSDictionary?
        let out = NSAppleScript(source: src)?.executeAndReturnError(&err)
        return err == nil ? out?.stringValue : nil
    }

    private func parse(_ raw: String, source: String) -> (Track, Bool, Double, Double)? {
        let p = raw.components(separatedBy: "||")
        guard p.count >= 8 else { return nil }
        func num(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0 }
        var dur = num(p[4])
        if source == "Spotify" { dur /= 1000 }
        let art = URL(string: p[6].replacingOccurrences(of: "http://", with: "https://"))
        let t = Track(title: p[1], artist: p[2], album: p[3], duration: dur, artworkURL: art, source: source)
        return (t, p[0].lowercased().contains("playing"), num(p[5]), num(p[7]))
    }

    func poll() {
        let now = Date()
        let dt = min(now.timeIntervalSince(lastPoll), 2.5)
        lastPoll = now
        var found: [(Track, Bool, Double, Double)] = []
        if running("com.spotify.client"), let r = run(spotifyScript), let x = parse(r, source: "Spotify") { found.append(x) }
        if running("com.apple.Music"), let r = run(musicScript), let x = parse(r, source: "Music") { found.append(x) }
        guard let pick = found.first(where: { $0.1 }) ?? found.first else {
            if track != nil { track = nil; artwork = nil }
            if isPlaying {
                isPlaying = false
                rescheduleTimer()
            }
            return
        }
        if track != pick.0 { track = pick.0; loadArtwork(pick.0) }
        let wasPlaying = isPlaying
        isPlaying = pick.1
        if wasPlaying != isPlaying {
            rescheduleTimer()
        }
        basePosition = pick.2
        baseDate = Date()
        volume = pick.3
        Diary.shared.tick(pick.0, playing: pick.1, dt: dt)
    }

    // MARK: controls

    func command(_ cmd: String) {
        guard let app = track?.source else { return }
        _ = run("tell application \"\(app)\" to \(cmd)")
        poll()
    }

    func seek(to s: Double) {
        command("set player position to \(String(format: "%.2f", s))")
    }

    func setVolume(_ v: Double) {
        command("set sound volume to \(Int(v))")
    }

    // MARK: artwork + colours

    private func loadArtwork(_ t: Track) {
        artTask?.cancel()
        let cacheKey = "\(t.artist) - \(t.album.isEmpty ? t.title : t.album)" as NSString
        if let cached = Self.artCache.object(forKey: cacheKey) {
            self.artwork = cached
            var c = cached.dominantColors()
            if !c.isEmpty {
                while c.count < 3 { c.append(c[c.count % max(1, c.count)]) }
                self.colors = c
            }
            return
        }

        artwork = nil
        colors = palette(t.title)
        artTask = Task {
            var url = t.artworkURL
            if url == nil { url = await Self.itunesArt(t) }
            guard let u = url, let (data, _) = try? await URLSession.shared.data(from: u),
                  let img = NSImage(data: data), !Task.isCancelled else { return }
            Self.artCache.setObject(img, forKey: cacheKey)
            artwork = img
            var c = img.dominantColors()
            if !c.isEmpty {
                while c.count < 3 { c.append(c[c.count % max(1, c.count)]) }
                colors = c
            }
        }
    }

    /// Apple Music has no artwork URL via AppleScript, so look it up on the free iTunes Search API.
    private static func itunesArt(_ t: Track) async -> URL? {
        struct R: Decodable { struct I: Decodable { var artworkUrl100: String? }; var results: [I] }
        var c = URLComponents(string: "https://itunes.apple.com/search")!
        c.queryItems = [.init(name: "term", value: "\(t.artist) \(t.title)"),
                        .init(name: "entity", value: "song"), .init(name: "limit", value: "1")]
        guard let (d, _) = try? await URLSession.shared.data(from: c.url!),
              let r = try? JSONDecoder().decode(R.self, from: d),
              let s = r.results.first?.artworkUrl100 else { return nil }
        return URL(string: s.replacingOccurrences(of: "100x100", with: "600x600"))
    }
}
