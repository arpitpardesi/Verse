import SwiftUI

/// Lyrics window / full-screen wrapper: floating luxury glass controls fade in when the mouse is over the window.
struct LyricsContainer: View {
    let rounded: Bool
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared
    @AppStorage(K.mode) private var mode = "island"
    @AppStorage(K.theme) private var theme = LyricTheme.cotodama.rawValue
    @AppStorage(K.artLyrics) private var artOn = true
    @State private var hovering = false
    @State private var copiedCard = false

    var tint: Color { np.colors.first ?? Color(red: 1.0, green: 0.28, blue: 0.58) }

    var body: some View {
        LyricsView()
            .clipShape(RoundedRectangle(cornerRadius: rounded ? 28 : 0, style: .continuous))
            .overlay {
                if rounded {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.24), Color.white.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            }
            .overlay(alignment: .top) {
                if mode != "desktop" {
                    topBar
                        .opacity(hovering ? 1 : 0)
                        .offset(y: hovering ? 0 : -8)
                        .allowsHitTesting(hovering)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hovering)
                }
            }
            .overlay(alignment: .bottom) {
                if mode != "desktop" {
                    bottomBar
                        .opacity(hovering ? 1 : 0)
                        .offset(y: hovering ? 0 : 8)
                        .allowsHitTesting(hovering)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hovering)
                }
            }
            .onHover { h in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    hovering = h
                }
            }
    }

    func iconButton(_ name: String, help: String = "", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - Floating Liquid Glass Top HUD

    var topBar: some View {
        HStack(spacing: 12) {
            // Theme & View Menus
            HStack(spacing: 8) {
                Menu {
                    Section("COTODAMA Lyric Speaker") {
                        Button("COTODAMA Lyric Sync (Auto)") { theme = LyricTheme.cotodama.rawValue }
                        Button("Cotodama Canvas Edition") { theme = LyricTheme.cotodamaCanvas.rawValue }
                        Button("Cotodama Box Edition") { theme = LyricTheme.cotodamaBox.rawValue }
                    }
                    Section("Featured Themes") {
                        Button("Big Words") { theme = LyricTheme.bigWord.rawValue }
                        Button("Karaoke") { theme = LyricTheme.karaoke.rawValue }
                        Button("CD Disc") { theme = LyricTheme.disc.rawValue }
                        Button("Vinyl") { theme = LyricTheme.vinyl.rawValue }
                        Button("Liquid") { theme = LyricTheme.liquid.rawValue }
                        Button("Aura") { theme = LyricTheme.aura.rawValue }
                    }
                    Divider()
                    ForEach(LyricTheme.allCases) { th in
                        Button(th.title) { theme = th.rawValue }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "textformat")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(tint)
                        Text(LyricTheme(rawValue: theme)?.title ?? "Theme")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .opacity(0.6)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Divider()
                    .frame(height: 14)
                    .overlay(Color.white.opacity(0.2))

                Menu {
                    Button { mode = "island" } label: { Label("Dynamic Island", systemImage: "capsule.fill") }
                    Button { mode = "lyrics" } label: { Label("Lyrics Window", systemImage: "macwindow") }
                    Button { mode = "fullscreen" } label: { Label("Full Screen", systemImage: "arrow.up.left.and.arrow.down.right") }
                    Button { mode = "desktop" } label: { Label("Desktop Lyrics", systemImage: "menubar.dock.rectangle") }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: modeIcon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(modeTitle)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .opacity(0.6)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(red: 0.06, green: 0.06, blue: 0.08).opacity(0.85), in: Capsule())
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(LinearGradient(colors: [Color.white.opacity(0.26), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom), lineWidth: 0.9))
            .shadow(color: Color.black.opacity(0.35), radius: 10, y: 4)

            Spacer()

            // Synchronized Audio Micro-HUD
            HStack(spacing: 6) {
                Button { lyrics.nudge(-1) } label: {
                    Text("−1s").font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .buttonStyle(.plain)

                Button { lyrics.nudge(-0.1) } label: {
                    Text("−.1").font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .buttonStyle(.plain)

                Button {
                    lyrics.offset = 0.0
                } label: {
                    Text(abs(lyrics.offset) < 0.01 ? "SYNC" : String(format: "%+.1fs", lyrics.offset))
                        .monospacedDigit()
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(abs(lyrics.offset) < 0.01 ? Color.green : tint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Click to reset sync offset to 0.0s")

                Button { lyrics.nudge(0.1) } label: {
                    Text("+.1").font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .buttonStyle(.plain)

                Button { lyrics.nudge(1) } label: {
                    Text("+1s").font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(red: 0.06, green: 0.06, blue: 0.08).opacity(0.85), in: Capsule())
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(LinearGradient(colors: [Color.white.opacity(0.26), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom), lineWidth: 0.9))
            .shadow(color: Color.black.opacity(0.35), radius: 10, y: 4)

            // Right Quick Actions Capsule
            HStack(spacing: 8) {
                iconButton(artOn ? "photo.fill" : "photo", help: "Toggle Album Artwork Backdrop") {
                    withAnimation(.spring(response: 0.3)) { artOn.toggle() }
                }
                .foregroundStyle(artOn ? tint : .white.opacity(0.7))

                iconButton(copiedCard ? "checkmark" : "square.and.arrow.up", help: "Copy Lyric Card") {
                    Sharing.copyCard()
                    withAnimation(.spring(response: 0.3)) { copiedCard = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.spring(response: 0.3)) { copiedCard = false }
                    }
                }
                .foregroundStyle(copiedCard ? Color.green : .white.opacity(0.7))

                iconButton("chevron.up.circle.fill", help: "Dock back to Dynamic Island") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        mode = "island"
                    }
                }
                .foregroundStyle(tint)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.06, green: 0.06, blue: 0.08).opacity(0.85), in: Capsule())
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(LinearGradient(colors: [Color.white.opacity(0.26), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom), lineWidth: 0.9))
            .shadow(color: Color.black.opacity(0.35), radius: 10, y: 4)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.top, 16)
    }

    private var modeTitle: String {
        switch mode {
        case "island": return "Island"
        case "lyrics": return "Window"
        case "fullscreen": return "Full"
        case "desktop": return "Desktop"
        default: return "View"
        }
    }

    private var modeIcon: String {
        switch mode {
        case "island": return "capsule.fill"
        case "lyrics": return "macwindow"
        case "fullscreen": return "arrow.up.left.and.arrow.down.right"
        case "desktop": return "menubar.dock.rectangle"
        default: return "rectangle.on.rectangle"
        }
    }

    // MARK: - Floating Liquid Glass Bottom Player Dock

    var bottomBar: some View {
        VStack(spacing: 8) {
            // Interactive Seek Bar
            SeekBar(tint: tint, fg: .white)

            HStack(spacing: 14) {
                // Album Art Squircle
                CoverView(art: np.artwork, size: 42, radius: 9)
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                    .shadow(color: tint.opacity(0.35), radius: 6)

                // Track Info & Audio Equalizer
                VStack(alignment: .leading, spacing: 2) {
                    Text(np.track?.title ?? "Nothing playing")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(np.track?.artist ?? "Open Spotify or Apple Music")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(1)
                        if np.isPlaying {
                            EqualizerBars(tint: tint, height: 12)
                        }
                    }
                }

                Spacer()

                // Transport Controls Dock
                HStack(spacing: 16) {
                    Button { np.command("previous track") } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 30, height: 30)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button { np.command("playpause") } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [tint, tint.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 36, height: 36)
                                .shadow(color: tint.opacity(0.55), radius: 8)
                            Image(systemName: np.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: np.isPlaying ? 0 : 1)
                        }
                    }
                    .buttonStyle(.plain)

                    Button { np.command("next track") } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 30, height: 30)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.05, green: 0.05, blue: 0.07).opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 16, y: 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
