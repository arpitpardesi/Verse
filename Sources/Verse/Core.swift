import SwiftUI
import AppKit

enum AppInfo {
    static let version = "2.2.1"
}

enum K {
    static let mode = "mode", theme = "theme", background = "background", font = "fontStyle"
    static let align = "align", scale = "scale", upper = "upper", accent = "accent"
    static let shape = "islandShape", hover = "expandOnHover", glow = "edgeGlow"
    static let record = "recordWidget", recordStyle = "recordStyle"
    static let scatter = "scatter", lean = "lean"
    static let artLyrics = "artLyrics", artIsland = "artIsland", artEffect = "artEffect", artDim = "artDim"
    static let glowStyle = "glowStyle", glowSync = "glowSync", glowColor = "glowColor"
    static let glowIntensity = "glowIntensity", glowWidth = "glowWidth", glowBPM = "glowBPM", glowSens = "glowSens"
    static let city = "city", unit = "tempUnit", expanded = "islandExpanded"
}

extension Notification.Name {
    static let verseSettings = Notification.Name("verse.settings")
}

enum LyricTheme: String, CaseIterable, Identifiable {
    case cotodama, cotodamaCanvas, cotodamaFlow, cotodamaBeat, cotodamaBox, cotodamaVisualizer, bigWord, jumble, metric, wave, pop, echo, cinema, liquid, synthwave, vinyl, glitch, orbit, bigWords, karaoke, neon, terminal, aura, minimal, lens, stars, typewriter, poster, cyberpunk, quantum, whisper, zen, prism, aurora, cassette, spotlight, magazine, ipod, matrix, radar, disc
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cotodama: return "COTODAMA (Lyric Sync Engine)"
        case .cotodamaVisualizer: return "COTODAMA Visualizer"
        case .cotodamaCanvas: return "Cotodama Canvas"
        case .cotodamaFlow: return "Cotodama Flow"
        case .cotodamaBeat: return "Cotodama Kinetic"
        case .cotodamaBox: return "Cotodama Box"
        case .bigWord: return "Big Words"
        case .jumble: return "Jumble"
        case .metric: return "Metric"
        case .wave: return "Wave"
        case .pop: return "Pop"
        case .echo: return "Echo"
        case .cinema: return "Cinema"
        case .liquid: return "Liquid"
        case .synthwave: return "Synthwave"
        case .vinyl: return "Vinyl"
        case .glitch: return "Glitch"
        case .orbit: return "Orbit"
        case .bigWords: return "Big Lines"
        case .karaoke: return "Karaoke"
        case .neon: return "Neon"
        case .terminal: return "Terminal"
        case .aura: return "Aura"
        case .minimal: return "Minimal"
        case .lens: return "Lens"
        case .stars: return "Stars"
        case .typewriter: return "Typewriter"
        case .poster: return "Poster"
        case .cyberpunk: return "Cyberpunk"
        case .quantum: return "Quantum"
        case .whisper: return "Whisper"
        case .zen: return "Zen"
        case .prism: return "Prism"
        case .aurora: return "Aurora"
        case .cassette: return "Cassette"
        case .spotlight: return "Spotlight"
        case .magazine: return "Magazine"
        case .ipod: return "Classic Pod"
        case .matrix: return "Matrix"
        case .radar: return "Radar"
        case .disc: return "CD Disc"
        }
    }
}

struct Track: Equatable {
    var title: String
    var artist: String
    var album: String
    var duration: Double
    var artworkURL: URL?
    var source: String   // "Spotify" or "Music"
}

func supportDir() -> URL {
    let u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Verse")
    try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
    return u
}

func palette(_ seed: String) -> [Color] {
    let raw = seed.unicodeScalars.reduce(7) { ($0 &* 31) &+ Int($1.value) }
    let h = ((raw % 360) + 360) % 360
    return [0, 40, 200].map { Color(hue: Double((h + $0) % 360) / 360, saturation: 0.7, brightness: 0.85) }
}

func verseFont(_ style: String, _ size: CGFloat, _ weight: Font.Weight) -> Font {
    switch style {
    case "serif": return .system(size: size, weight: weight, design: .serif)
    case "mono": return .system(size: size, weight: weight, design: .monospaced)
    case "default": return .system(size: size, weight: weight)
    default: return .system(size: size, weight: weight, design: .rounded)
    }
}

func verseAccent(_ key: String, _ cover: [Color]) -> Color {
    switch key {
    case "pink": return Color(red: 1, green: 0.3, blue: 0.7)
    case "cyan": return .cyan
    case "green": return Color(red: 0.25, green: 1, blue: 0.5)
    case "orange": return .orange
    case "white": return .white
    default: return cover.first ?? .pink
    }
}

func fmtTime(_ s: Double) -> String {
    let n = Int(max(0, s))
    return String(format: "%d:%02d", n / 60, n % 60)
}

/// Text style passed to every lyric theme.
struct LStyle {
    var font = "rounded"
    var scale = 1.0
    var align: TextAlignment = .center
    var upper = false
    var accent: Color = .pink
    var colors: [Color] = [.purple, .blue, .pink]
    var scatter = 0.5
    var lean = 0.5

    func f(_ size: CGFloat, _ w: Font.Weight = .bold) -> Font { verseFont(font, size * CGFloat(scale), w) }
    func c(_ i: Int) -> Color { colors.isEmpty ? .pink : colors[i % colors.count] }
    func t(_ s: String) -> String { s.isEmpty ? "♪" : (upper ? s.uppercased() : s) }
    var frameAlign: Alignment { align == .leading ? .leading : .center }
}

extension NSImage {
    /// Picks up to 3 vivid dominant colours from the artwork.
    func dominantColors() -> [Color] {
        guard let cg = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return [] }
        let w = 24, h = 24
        var px = [UInt8](repeating: 0, count: w * h * 4)
        px.withUnsafeMutableBytes { buf in
            guard let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                      bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        var weight = [Double](repeating: 0, count: 12)
        var sum = [(Double, Double, Double)](repeating: (0, 0, 0), count: 12)
        for i in 0..<(w * h) {
            let c = NSColor(red: CGFloat(px[i * 4]) / 255, green: CGFloat(px[i * 4 + 1]) / 255,
                            blue: CGFloat(px[i * 4 + 2]) / 255, alpha: 1)
            var hh: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
            c.getHue(&hh, saturation: &s, brightness: &v, alpha: &a)
            let wt = Double(s * v) + 0.02
            let b = min(11, Int(hh * 12))
            weight[b] += wt
            sum[b] = (sum[b].0 + Double(hh) * wt, sum[b].1 + Double(s) * wt, sum[b].2 + Double(v) * wt)
        }
        let top = weight.enumerated().sorted { $0.element > $1.element }.prefix(3).filter { $0.element > 0.05 }
        return top.map {
            let t = sum[$0.offset], wt = weight[$0.offset]
            return Color(hue: t.0 / wt, saturation: min(1, max(0.45, t.1 / wt)), brightness: min(1, max(0.65, t.2 / wt)))
        }
    }
}

struct CoverView: View {
    var art: NSImage?
    var size: CGFloat
    var radius: CGFloat? = nil
    var body: some View {
        Group {
            if let art {
                Image(nsImage: art).resizable().scaledToFill()
            } else {
                ZStack { Color.white.opacity(0.12); Image(systemName: "music.note").foregroundStyle(.white.opacity(0.6)) }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius ?? size * 0.22, style: .continuous))
    }
}

/// Real notch geometry of the main display, so nothing is ever drawn under the camera cut-out.
enum NotchInfo {
    static var hasNotch: Bool { (NSScreen.main?.safeAreaInsets.top ?? 0) > 0 }
    /// Height of the notch (or a menu-bar-sized strip on Macs without one).
    static var height: CGFloat { hasNotch ? (NSScreen.main?.safeAreaInsets.top ?? 32) : 28 }
    /// Width of the notch cut-out; 0 on Macs without one.
    static var width: CGFloat {
        guard hasNotch, let scr = NSScreen.main,
              let l = scr.auxiliaryTopLeftArea, let r = scr.auxiliaryTopRightArea else { return 0 }
        return max(0, scr.frame.width - l.width - r.width)
    }
}
