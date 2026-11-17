import SwiftUI

/// The menu-bar popover. View, theme and effects are all compact dropdowns.
struct MenuView: View {
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared
    @ObservedObject var updater = UpdateManager.shared
    @AppStorage(K.mode) private var mode = "island"
    @AppStorage(K.theme) private var theme = LyricTheme.bigWord.rawValue
    @AppStorage(K.artLyrics) private var artLyrics = true
    @AppStorage(K.artIsland) private var artIsland = true
    @AppStorage(K.artEffect) private var artEffect = "aura"
    @AppStorage(K.glow) private var glow = false
    @AppStorage(K.glowStyle) private var glowStyle = "rim"
    @AppStorage(K.glowWidth) private var glowWidth = 6.0
    @AppStorage(K.glowSync) private var glowSync = "audio"
    @AppStorage(K.record) private var record = false

    var tint: Color { np.colors.first ?? .pink }

    func transport(_ name: String, _ size: CGFloat, _ cmd: String) -> some View {
        Button { np.command(cmd) } label: { Image(systemName: name).font(.system(size: size)) }
            .buttonStyle(.plain)
    }

    func row<C: View>(_ title: String, _ icon: String, @ViewBuilder _ content: () -> C) -> some View {
        HStack {
            Label(title, systemImage: icon).font(.system(size: 12))
            Spacer()
            content().pickerStyle(.menu).labelsHidden().frame(width: 160)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            // Optional OTA Update Available banner
            if updater.hasUpdate {
                Button {
                    NotificationCenter.default.post(name: .verseSettings, object: nil)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.pink)
                        Text("New Update Available")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("Install")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.pink)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.pink.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.pink.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Now playing card
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    CoverView(art: np.artwork, size: 60, radius: 12)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(np.track?.title ?? "Nothing playing").font(.system(size: 15, weight: .semibold)).lineLimit(1)
                        Text(np.track?.artist ?? "Open Spotify or Music").font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                        Text(np.track?.album ?? "").font(.system(size: 11)).foregroundStyle(.tertiary).lineLimit(1)
                    }
                    Spacer()
                    EqualizerBars(tint: tint, height: 18)
                }
                SeekBar(tint: tint, fg: .primary)
                HStack(spacing: 30) {
                    transport("backward.fill", 16, "previous track")
                    transport(np.isPlaying ? "pause.circle.fill" : "play.circle.fill", 34, "playpause")
                    transport("forward.fill", 16, "next track")
                }
            }
            .padding(14)
            .background(LinearGradient(colors: [tint.opacity(0.28), tint.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            // View + theme dropdowns
            VStack(spacing: 8) {
                row("View", "rectangle.on.rectangle") {
                    Picker("", selection: $mode) {
                        Text("Island (notch)").tag("island"); Text("Lyrics window").tag("lyrics")
                        Text("Full screen").tag("fullscreen"); Text("Desktop lyrics").tag("desktop"); Text("Hidden").tag("hidden")
                    }
                }
                row("Theme", "textformat") {
                    Picker("", selection: $theme) {
                        ForEach(LyricTheme.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                }
            }

            Divider()

            // Effects
            VStack(spacing: 8) {
                Toggle(isOn: $artLyrics) { Label("Album art in lyrics", systemImage: "photo") }
                if artLyrics {
                    row("Art effect", "wand.and.stars") {
                        Picker("", selection: $artEffect) { ForEach(ArtEffect.allCases) { Text($0.title).tag($0.rawValue) } }
                    }
                }
                Toggle(isOn: $artIsland) { Label("Album art in island", systemImage: "capsule") }
                Toggle(isOn: $glow) { Label("Edge glow", systemImage: "sparkles") }
                if glow {
                    row("Glow style", "paintbrush") {
                        Picker("", selection: $glowStyle) {
                            Text("Beat Glow Rim").tag("rim")
                            Text("Border glow").tag("border")
                            Text("Ripple").tag("ripple")
                            Text("Spectrum bars").tag("spectrum")
                            Text("Corner flares").tag("corners")
                            Text("Aurora").tag("aurora")
                        }
                    }
                    HStack {
                        Label("Thickness", systemImage: "lineweight").font(.system(size: 12))
                        Spacer()
                        Slider(value: $glowWidth, in: 1...30, step: 1).frame(width: 100)
                        Text("\(Int(glowWidth)) pt").monospacedDigit().font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 34, alignment: .trailing)
                    }
                    row("Beat sync", "metronome") {
                        Picker("", selection: $glowSync) {
                            Text("Live audio").tag("audio"); Text("Tempo (BPM)").tag("bpm")
                            Text("Lyric lines").tag("lyrics"); Text("Breathing").tag("smooth")
                        }
                    }
                }
                Toggle(isOn: $record) { Label("Desktop record", systemImage: "record.circle") }
            }
            .toggleStyle(.switch).controlSize(.small).font(.system(size: 12))

            // Sync
            HStack(spacing: 6) {
                Label("Sync", systemImage: "timer").font(.system(size: 12))
                Spacer()
                Button("−1") { lyrics.nudge(-1) }
                Button("−.1") { lyrics.nudge(-0.1) }
                Text(String(format: "%+.1fs", lyrics.offset)).monospacedDigit().frame(width: 48).font(.system(size: 12))
                Button("+.1") { lyrics.nudge(0.1) }
                Button("+1") { lyrics.nudge(1) }
            }
            .controlSize(.small)

            Divider()
            HStack {
                Button { Sharing.copyCard() } label: { Label("Card", systemImage: "square.and.arrow.up") }
                Button { Sharing.setWallpaper() } label: { Label("Wallpaper", systemImage: "photo.artframe") }
                Spacer()
                Button { NotificationCenter.default.post(name: .verseSettings, object: nil) } label: { Image(systemName: "gearshape") }
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }
            }
            .buttonStyle(.plain).font(.system(size: 12))
        }
        .padding(16).frame(width: 380)
    }
}
