import SwiftUI
import AppKit

struct LyricCardView: View {
    let title: String
    let artist: String
    let lines: [String]
    let colors: [Color]
    let art: NSImage?
    var body: some View {
        ZStack {
            LinearGradient(colors: [colors.first ?? .purple, colors.count > 1 ? colors[1] : .blue, .black],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 28) {
                if let art { CoverView(art: art, size: 140, radius: 20) }
                Spacer()
                ForEach(Array(lines.enumerated()), id: \.offset) { _, l in
                    Text(l).font(.system(size: 64, weight: .heavy, design: .rounded)).minimumScaleFactor(0.5)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 34, weight: .semibold))
                    Text(artist).font(.system(size: 28)).opacity(0.7)
                }
                Text("Verse").font(.system(size: 22, weight: .bold, design: .rounded)).opacity(0.45)
            }
            .foregroundStyle(.white)
            .padding(80).frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 1080, height: 1080)
    }
}

struct WallpaperView: View {
    let colors: [Color]
    let art: NSImage?
    let size: CGSize
    var body: some View {
        ZStack {
            Color.black
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(colors[i % max(1, colors.count)]).frame(width: size.width * 0.6)
                        .offset(x: CGFloat(i - 1) * size.width * 0.3, y: (i % 2 == 0 ? -1 : 1) * size.height * 0.15)
                }
            }
            .blur(radius: size.width * 0.08)
            if let art { CoverView(art: art, size: size.height * 0.34, radius: 24).shadow(radius: 30) }
        }
        .frame(width: size.width, height: size.height).clipped()
    }
}

@MainActor
enum Sharing {
    private static func png(_ img: NSImage) -> Data? {
        guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    /// Renders the current lyric as a shareable square image: copied to clipboard + saved to Desktop.
    static func copyCard() {
        let np = NowPlaying.shared
        guard let t = np.track else { return }
        var ls: [String] = []
        if case .synced(let lines) = LyricsStore.shared.state {
            let i = lineIndex(lines, np.position() + LyricsStore.shared.totalOffset)
            if i >= 0 { ls = (i...min(i + 2, lines.count - 1)).map { lines[$0].text }.filter { !$0.isEmpty } }
        }
        if ls.isEmpty { ls = [t.title] }
        let r = ImageRenderer(content: LyricCardView(title: t.title, artist: t.artist, lines: ls, colors: np.colors, art: np.artwork))
        r.scale = 1
        guard let img = r.nsImage else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([img])
        if let data = png(img) {
            let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Verse – \(t.title).png")
            try? data.write(to: url)
        }
        NSSound(named: "Pop")?.play()
    }

    static func setWallpaper() {
        guard let screen = NSScreen.main else { return }
        let np = NowPlaying.shared
        let r = ImageRenderer(content: WallpaperView(colors: np.colors, art: np.artwork, size: screen.frame.size))
        r.scale = screen.backingScaleFactor
        guard let img = r.nsImage, let data = png(img) else { return }
        let url = supportDir().appendingPathComponent("wallpaper-\(Int(Date().timeIntervalSince1970)).png")
        try? data.write(to: url)
        try? NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
    }
}
