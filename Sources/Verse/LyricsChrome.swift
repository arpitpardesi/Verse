import SwiftUI

/// Lyrics window / full-screen wrapper: controls fade in when the mouse is over the window.
struct LyricsContainer: View {
    let rounded: Bool
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared
    @AppStorage(K.mode) private var mode = "island"
    @AppStorage(K.theme) private var theme = LyricTheme.bigWord.rawValue
    @AppStorage(K.artLyrics) private var artOn = true
    @State private var hovering = false

    var body: some View {
        LyricsView()
            .clipShape(RoundedRectangle(cornerRadius: rounded ? 28 : 0, style: .continuous))
            .overlay(alignment: .top) {
                if mode != "desktop" { topBar.opacity(hovering ? 1 : 0).allowsHitTesting(hovering) }
            }
            .overlay(alignment: .bottom) {
                if mode != "desktop" { bottomBar.opacity(hovering ? 1 : 0).allowsHitTesting(hovering) }
            }
            .onHover { h in withAnimation(.easeOut(duration: 0.2)) { hovering = h } }
    }

    func icon(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: name).font(.system(size: 14)) }
    }

    var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Menu {
                    ForEach(LyricTheme.allCases) { th in Button(th.title) { theme = th.rawValue } }
                } label: { Label(LyricTheme(rawValue: theme)?.title ?? "Theme", systemImage: "textformat") }
                Menu {
                    Button("Island") { mode = "island" }
                    Button("Lyrics window") { mode = "lyrics" }
                    Button("Full screen") { mode = "fullscreen" }
                    Button("Desktop lyrics") { mode = "desktop" }
                } label: { Label("View", systemImage: "rectangle.on.rectangle") }
            }
            .menuStyle(.borderlessButton).fixedSize()
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            Spacer()
            HStack(spacing: 10) {
                Button("−1") { lyrics.nudge(-1) }
                Button("−.1") { lyrics.nudge(-0.1) }
                Text(String(format: "%+.1fs", lyrics.offset)).monospacedDigit()
                Button("+.1") { lyrics.nudge(0.1) }
                Button("+1") { lyrics.nudge(1) }
            }
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            HStack(spacing: 14) {
                icon(artOn ? "photo.fill" : "photo") { artOn.toggle() }
                icon("square.and.arrow.up") { Sharing.copyCard() }
                icon("chevron.up.circle") { mode = "island" }
            }
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain).foregroundStyle(.white).padding(14)
    }

    var bottomBar: some View {
        VStack(spacing: 6) {
            SeekBar(tint: np.colors.first ?? .pink)
            HStack(spacing: 12) {
                CoverView(art: np.artwork, size: 40, radius: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(np.track?.title ?? "Nothing playing").font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    Text(np.track?.artist ?? "").font(.system(size: 11)).opacity(0.65).lineLimit(1)
                }
                Spacer()
                HStack(spacing: 22) {
                    icon("backward.fill") { np.command("previous track") }
                    icon(np.isPlaying ? "pause.fill" : "play.fill") { np.command("playpause") }
                    icon("forward.fill") { np.command("next track") }
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(14)
    }

    func cycleTheme() {
        let all = LyricTheme.allCases
        let cur = all.firstIndex { $0.rawValue == theme } ?? 0
        theme = all[(cur + 1) % all.count].rawValue
    }
}
