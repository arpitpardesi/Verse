import SwiftUI

/// The redesigned luxury menu-bar popover for Verse.
/// Apple Obsidian Glass & Liquid Retina aesthetic.
struct MenuView: View {
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared
    @ObservedObject var updater = UpdateManager.shared

    @AppStorage(K.mode) private var mode = "island"
    @AppStorage(K.theme) private var theme = LyricTheme.cotodama.rawValue
    @AppStorage(K.artLyrics) private var artLyrics = true
    @AppStorage(K.artIsland) private var artIsland = true
    @AppStorage(K.artEffect) private var artEffect = "aura"
    @AppStorage(K.glow) private var glow = false
    @AppStorage(K.glowStyle) private var glowStyle = "rim"
    @AppStorage(K.glowWidth) private var glowWidth = 6.0
    @AppStorage(K.glowSync) private var glowSync = "audio"
    @AppStorage(K.record) private var record = false
    @AppStorage(K.recordStyle) private var recordStyle = "turntable"

    @State private var copiedCard = false
    @State private var wallpaperSet = false

    var tint: Color { np.colors.first ?? Color(red: 1.0, green: 0.28, blue: 0.58) }

    var body: some View {
        VStack(spacing: 12) {
            // Header Bar
            headerBar

            // Optional OTA Update Alert Banner
            if updater.hasUpdate {
                updateBanner
            }

            // Hero Now Playing Card
            nowPlayingCard

            // Display Mode Segmented Switcher
            displayModeSwitcher

            // Lyric Theme Picker Card
            themePickerCard

            // Visuals & Effects Section
            visualsCard

            // Edge Beat Glow Section
            glowCard

            // Karaoke Sync Offset Section
            syncCard

            Divider()
                .overlay(Color.white.opacity(0.12))

            // Footer Quick Actions
            footerBar
        }
        .padding(16)
        .frame(width: 384)
        .background(
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.09)
                    .opacity(0.94)
                .background(.ultraThinMaterial)

                // Ambient Radial Light
                RadialGradient(
                    colors: [tint.opacity(0.18), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 280
                )
            }
        )
    }

    // MARK: - Header Bar

    var headerBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Text("Verse")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("v\(UpdateManager.shared.currentVersion)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tint.opacity(0.15), in: Capsule())
                    .overlay(Capsule().stroke(tint.opacity(0.3), lineWidth: 0.7))
            }

            Spacer()

            // Source Indicator & Controls
            HStack(spacing: 10) {
                if let track = np.track {
                    HStack(spacing: 4) {
                        Image(systemName: track.source == "Spotify" ? "waveform" : "apple.logo")
                            .font(.system(size: 10, weight: .semibold))
                        Text(track.source)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08), in: Capsule())
                }

                Button {
                    NotificationCenter.default.post(name: .verseSettings, object: nil)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Settings & Preferences")

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Quit Verse")
            }
        }
    }

    // MARK: - OTA Update Banner

    var updateBanner: some View {
        Button {
            NotificationCenter.default.post(name: .verseSettings, object: nil)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 26, height: 26)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Verse Update Ready")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Click to view details & install")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Text("Install")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(tint, in: Capsule())
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.22), tint.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(tint.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero Now Playing Card

    var nowPlayingCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Album Art Squircle
                CoverView(art: np.artwork, size: 58, radius: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.32), Color.white.opacity(0.08)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: tint.opacity(0.35), radius: 8, y: 3)

                // Title & Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(np.track?.title ?? "Nothing playing")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(np.track?.artist ?? "Open Spotify or Apple Music")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)

                    if let album = np.track?.album, !album.isEmpty {
                        Text(album)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Animated Equalizer Bars
                if np.isPlaying {
                    EqualizerBars(tint: tint, height: 18)
                }
            }

            // Seek Bar
            SeekBar(tint: tint, fg: .white)

            // Transport Dock
            HStack(spacing: 28) {
                Button { np.command("previous track") } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)

                Button { np.command("playpause") } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 38, height: 38)
                            .shadow(color: tint.opacity(0.6), radius: 8)
                        Image(systemName: np.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: np.isPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)

                Button { np.command("next track") } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).opacity(0.88)
                LinearGradient(
                    colors: [tint.opacity(0.24), tint.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, y: 4)
    }

    // MARK: - Display Mode Switcher

    var displayModeSwitcher: some View {
        HStack(spacing: 6) {
            modePill("island", title: "Island", icon: "capsule.fill")
            modePill("lyrics", title: "Window", icon: "macwindow")
            modePill("fullscreen", title: "Full", icon: "arrow.up.left.and.arrow.down.right")
            modePill("desktop", title: "Desktop", icon: "menubar.dock.rectangle")
        }
        .padding(4)
        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    func modePill(_ key: String, title: String, icon: String) -> some View {
        let selected = mode == key
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                mode = key
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: selected ? .bold : .medium))
                Text(title)
                    .font(.system(size: 11, weight: selected ? .bold : .medium, design: .rounded))
            }
            .foregroundStyle(selected ? Color.white : Color.white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Group {
                    if selected {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.75), tint.opacity(0.55)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                            )
                            .shadow(color: tint.opacity(0.4), radius: 5)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lyric Theme Picker Card

    var themePickerCard: some View {
        HStack {
            Label("Theme", systemImage: "textformat")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            Spacer()

            // Random Surprise Theme Button
            Button {
                cycleThemeRandom()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 22, height: 22)
                    .background(tint.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Surprise Me (Pick a random theme)")

            // Menu Dropdown
            Menu {
                Section("COTODAMA Lyric Speaker") {
                    themeItem(.cotodama)
                    themeItem(.cotodamaCanvas)
                    themeItem(.cotodamaBox)
                }

                Section("Featured") {
                    themeItem(.bigWord)
                    themeItem(.karaoke)
                    themeItem(.disc)
                    themeItem(.vinyl)
                    themeItem(.liquid)
                    themeItem(.aura)
                }

                Section("Cosmic & Motion") {
                    themeItem(.synthwave)
                    themeItem(.stars)
                    themeItem(.aurora)
                    themeItem(.quantum)
                    themeItem(.lens)
                    themeItem(.glitch)
                }

                Section("Iconic & Retro") {
                    themeItem(.ipod)
                    themeItem(.cassette)
                    themeItem(.typewriter)
                    themeItem(.cinema)
                    themeItem(.poster)
                }

                Section("Cyber & Glow") {
                    themeItem(.neon)
                    themeItem(.matrix)
                    themeItem(.terminal)
                    themeItem(.cyberpunk)
                    themeItem(.radar)
                }

                Section("Minimal & Clean") {
                    themeItem(.minimal)
                    themeItem(.zen)
                    themeItem(.whisper)
                    themeItem(.metric)
                    themeItem(.magazine)
                    themeItem(.prism)
                }
            } label: {
                HStack(spacing: 5) {
                    Text(LyricTheme(rawValue: theme)?.title ?? "Theme")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
    }

    private func themeItem(_ th: LyricTheme) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                theme = th.rawValue
            }
        } label: {
            HStack {
                Text(th.title)
                if theme == th.rawValue {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    private func cycleThemeRandom() {
        let all = LyricTheme.allCases
        if let next = all.filter({ $0.rawValue != theme }).randomElement() {
            withAnimation(.spring(response: 0.3)) {
                theme = next.rawValue
            }
        }
    }

    // MARK: - Visuals & Art Effects Card

    var visualsCard: some View {
        VStack(spacing: 8) {
            HStack {
                Toggle(isOn: $artLyrics) {
                    Label("Backdrop Album Art", systemImage: "photo.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer()

                if artLyrics {
                    Picker("", selection: $artEffect) {
                        ForEach(ArtEffect.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 110)
                    .controlSize(.small)
                }
            }

            HStack {
                Toggle(isOn: $artIsland) {
                    Label("Notch Album Art", systemImage: "capsule.portrait")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer()
            }

            HStack {
                Toggle(isOn: $record) {
                    Label("Desktop Vinyl Widget", systemImage: "record.circle")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer()

                if record {
                    Picker("", selection: $recordStyle) {
                        Text("Turntable").tag("turntable")
                        Text("Sleeve").tag("sleeve")
                        Text("Aura").tag("aura")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 100)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
    }

    // MARK: - Edge Beat Glow Card

    var glowCard: some View {
        VStack(spacing: 8) {
            HStack {
                Toggle(isOn: $glow) {
                    Label("Edge Beat Glow", systemImage: "sparkles")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(glow ? tint : .white.opacity(0.85))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer()

                if glow {
                    Picker("", selection: $glowStyle) {
                        Text("Needle Rim").tag("rim")
                        Text("Border Glow").tag("border")
                        Text("Ripple").tag("ripple")
                        Text("Spectrum").tag("spectrum")
                        Text("Flares").tag("corners")
                        Text("Aurora").tag("aurora")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 110)
                    .controlSize(.small)
                }
            }

            if glow {
                HStack(spacing: 8) {
                    Text("Thickness")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                    Slider(value: $glowWidth, in: 1...30, step: 1)
                        .controlSize(.mini)
                    Text("\(Int(glowWidth)) pt")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(width: 32, alignment: .trailing)
                }

                HStack {
                    Text("Beat Sync")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Picker("", selection: $glowSync) {
                        Text("Live audio").tag("audio")
                        Text("Tempo (BPM)").tag("bpm")
                        Text("Lyric lines").tag("lyrics")
                        Text("Breathing").tag("smooth")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
    }

    // MARK: - Karaoke Timing & Sync Card

    var syncCard: some View {
        HStack(spacing: 6) {
            Label("Sync", systemImage: "timer")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            Spacer()

            Button { lyrics.nudge(-1) } label: {
                Text("−1s").font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Button { lyrics.nudge(-0.1) } label: {
                Text("−.1").font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Button {
                lyrics.offset = 0.0
            } label: {
                Text(abs(lyrics.offset) < 0.01 ? "SYNC" : String(format: "%+.1fs", lyrics.offset))
                    .monospacedDigit()
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(abs(lyrics.offset) < 0.01 ? Color.green : tint)
                    .frame(width: 48)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .help("Click to reset offset")

            Button { lyrics.nudge(0.1) } label: {
                Text("+.1").font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Button { lyrics.nudge(1) } label: {
                Text("+1s").font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
    }

    // MARK: - Footer Bar

    var footerBar: some View {
        HStack(spacing: 8) {
            Button {
                Sharing.copyCard()
                withAnimation(.spring(response: 0.3)) { copiedCard = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.spring(response: 0.3)) { copiedCard = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: copiedCard ? "checkmark" : "square.and.arrow.up")
                    Text(copiedCard ? "Copied" : "Share Card")
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(copiedCard ? Color.green : .white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                Sharing.setWallpaper()
                withAnimation(.spring(response: 0.3)) { wallpaperSet = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.spring(response: 0.3)) { wallpaperSet = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: wallpaperSet ? "checkmark" : "photo.artframe")
                    Text(wallpaperSet ? "Applied" : "Wallpaper")
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(wallpaperSet ? Color.green : .white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
}
