import SwiftUI

/// Text whose colour "fills" left-to-right as the line is sung.
struct FillText: View {
    let text: String
    let p: Double
    let on: Color
    let off: Color
    var body: some View {
        Text(text).foregroundStyle(LinearGradient(
            stops: [.init(color: on, location: p), .init(color: off, location: min(1, p + 0.001))],
            startPoint: .leading, endPoint: .trailing))
    }
}

struct StarField: View {
    var tint: Color
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { ctx in
            Canvas { c, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                for i in 0..<90 {
                    let a = Double((i * 7919) % 1000) / 1000
                    let b = Double((i * 104729) % 997) / 997
                    let tw = 0.4 + 0.6 * abs(sin(t * (0.5 + a) + Double(i)))
                    let r = 1 + 2 * a
                    let rect = CGRect(x: a * size.width, y: b * size.height, width: r, height: r)
                    c.fill(Path(ellipseIn: rect), with: .color((i % 5 == 0 ? tint : Color.white).opacity(tw)))
                }
            }
        }
        .background(Color(red: 0.02, green: 0.02, blue: 0.08))
    }
}

struct ThemeBackground: View {
    let theme: LyricTheme
    let setting: String
    let colors: [Color]
    let art: NSImage?

    var body: some View {
        switch setting {
        case "black": Color.black
        case "glass": ZStack { Color.black.opacity(0.35); Rectangle().fill(.ultraThinMaterial) }
        case "cover" where art != nil:
            GeometryReader { g in
                ZStack {
                    Image(nsImage: art!).resizable().scaledToFill()
                        .frame(width: g.size.width, height: g.size.height).blur(radius: 50).saturation(1.3)
                    Color.black.opacity(0.45)
                }.clipped()
            }
        default: auto
        }
    }

    @ViewBuilder var auto: some View {
        let c0 = colors.first ?? .purple
        let c1 = colors.count > 1 ? colors[1] : .blue
        let c2 = colors.count > 2 ? colors[2] : .pink
        switch theme {
        case .bigWord: ZStack { Color.black; c0.opacity(0.18) }
        case .jumble: LinearGradient(colors: [Color(white: 0.04), c1.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .metric: Color(white: 0.06)
        case .bigWords: LinearGradient(colors: [.black, Color(white: 0.12)], startPoint: .top, endPoint: .bottom)
        case .karaoke: LinearGradient(colors: [c0.opacity(0.9), c2.opacity(0.7), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neon, .terminal: Color.black
        case .minimal: ZStack { Color.black.opacity(0.35); Rectangle().fill(.ultraThinMaterial) }
        case .lens: LinearGradient(colors: [c1.opacity(0.55), .black], startPoint: .top, endPoint: .bottom)
        case .typewriter: Color(white: 0.08)
        case .poster: ZStack { Color.black; c0.opacity(0.3) }
        case .stars: ZStack { Color.black; StarField(tint: c0).opacity(0.3) }
        case .aura:
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate / 4
                ZStack {
                    Color.black
                    ForEach(0..<3, id: \.self) { i in
                        Circle().fill(i == 0 ? c0 : (i == 1 ? c1 : c2)).frame(width: 420, height: 420)
                            .offset(x: CGFloat(sin(t + Double(i) * 2) * 220), y: CGFloat(cos(t * 0.8 + Double(i)) * 120))
                    }
                }
                .blur(radius: 90)
            }
        }
    }
}

struct SyncedLyrics: View {
    let theme: LyricTheme
    let lines: [LyricLine]
    let index: Int
    let pos: Double
    let s: LStyle

    func text(_ i: Int) -> String {
        guard i >= 0, i < lines.count else { return "" }
        return s.t(lines[i].text)
    }
    var cur: String { index < 0 ? "♪" : text(index) }
    var progress: Double {
        guard index >= 0, index < lines.count else { return 0 }
        let start = lines[index].time
        let end = index + 1 < lines.count ? lines[index + 1].time : start + 5
        return min(1, max(0, (pos - start) / max(0.5, min(end - start, 8) * 0.9)))
    }

    /// Words of the last three lines become stars; the word being sung is big and ringed.
    func starToks(_ wi: Int) -> [Constellation.Tok] {
        var out: [Constellation.Tok] = []
        guard index >= 0, index < lines.count else { return out }
        let spread = 0.45 + 0.55 * s.scatter
        for L in max(0, index - 2)...index {
            for (k, w) in wordsOf(lines[L].text).enumerated() {
                if L == index && k > wi { break }
                let rx = (jit(L, k + 3) + 1) / 2
                let ry = (jit(L + 11, k) + 1) / 2
                let d = (jit(L + 5, k + 9) + 1) / 2
                out.append(Constellation.Tok(id: L * 1000 + k, text: w,
                                             x: 0.5 + (rx - 0.5) * 0.8 * spread,
                                             y: 0.42 + (ry - 0.5) * 0.7 * spread,
                                             d: d, current: L == index && k == wi))
            }
        }
        return out
    }

    func wordsOf(_ t: String) -> [String] { t.split(separator: " ").map(String.init) }
    /// Deterministic pseudo-random value in -1...1.
    func jit(_ a: Int, _ b: Int) -> Double {
        let x = sin(Double(a) * 12.9898 + Double(b) * 78.233) * 43758.5453
        return (x - x.rounded(.down)) * 2 - 1
    }
    var lineDur: Double {
        guard index >= 0, index < lines.count else { return 0 }
        let st = lines[index].time
        return (index + 1 < lines.count ? lines[index + 1].time : st + 5) - st
    }
    func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10, weight: .semibold, design: .monospaced)).opacity(0.5)
            Text(value).font(.system(size: 22 * CGFloat(s.scale), weight: .bold, design: .monospaced))
        }
    }

    var body: some View {
        switch theme {
        case .bigWords:
            ZStack {
                Text(cur).font(s.f(64, .black)).multilineTextAlignment(s.align).minimumScaleFactor(0.3)
                    .padding(48).id(index).transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(duration: 0.35), value: index)

        case .karaoke:
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(lines) { l in
                            Group {
                                if l.id == index {
                                    FillText(text: s.t(l.text), p: progress, on: .white, off: .white.opacity(0.4))
                                } else {
                                    Text(s.t(l.text)).foregroundStyle(.white.opacity(0.35))
                                }
                            }
                            .font(s.f(30)).id(l.id)
                        }
                    }
                    .padding(.horizontal, 40).padding(.vertical, 160)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: index) { _, new in
                    withAnimation(.easeInOut(duration: 0.5)) { proxy.scrollTo(max(new, 0), anchor: .center) }
                }
            }

        case .neon:
            VStack(spacing: 16) {
                Text(text(index - 1)).font(s.f(20, .medium)).opacity(0.25)
                Text(cur).font(s.f(44, .heavy))
                    .foregroundStyle(s.accent)
                    .shadow(color: s.accent, radius: 6)
                    .shadow(color: s.c(1), radius: 22)
                    .id(index).transition(.opacity)
                Text(text(index + 1)).font(s.f(20, .medium)).opacity(0.25)
            }
            .multilineTextAlignment(.center).minimumScaleFactor(0.4).padding(40)
            .animation(.easeInOut(duration: 0.3), value: index)

        case .terminal:
            VStack(spacing: 10) {
                if index >= 0 {
                    ForEach(Array(max(0, index - 2)...index), id: \.self) { i in
                        let dotted = text(i).lowercased().split(separator: " ").joined(separator: ".")
                        (Text(dotted) + Text(i == index ? " █" : "").foregroundColor(.red))
                            .opacity(i == index ? 1 : 0.5)
                    }
                }
            }
            .font(.system(size: 20 * CGFloat(s.scale), weight: .medium, design: .monospaced))
            .foregroundStyle(Color(red: 0.62, green: 0.72, blue: 1))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)

        case .aura:
            ZStack {
                Text(cur).font(s.f(52)).multilineTextAlignment(s.align).minimumScaleFactor(0.3)
                    .padding(48).id(index).transition(.blurReplace)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.5), value: index)

        case .minimal:
            VStack(spacing: 6) {
                Text(cur).font(s.f(26, .semibold))
                Text(text(index + 1)).font(s.f(16, .regular)).opacity(0.5)
            }
            .multilineTextAlignment(.center).padding(40)
            .animation(.easeInOut(duration: 0.25), value: index)

        case .lens:
            VStack(spacing: 14) {
                ForEach(-3...3, id: \.self) { d in
                    Text(text(index + d))
                        .font(s.f(d == 0 ? 34 : 24, d == 0 ? .bold : .medium))
                        .opacity(d == 0 ? 1 : max(0.12, 0.55 - Double(abs(d)) * 0.15))
                        .blur(radius: d == 0 ? 0 : CGFloat(abs(d)) * 1.6)
                }
            }
            .multilineTextAlignment(.center).padding(40)
            .animation(.easeInOut(duration: 0.35), value: index)

        case .stars:
            let ws = index >= 0 ? wordsOf(lines[index].text) : []
            let wi = min(max(ws.count - 1, 0), Int(progress * Double(ws.count)))
            Constellation(toks: starToks(wi), s: s)
                .animation(.easeOut(duration: 0.35), value: index * 1000 + wi)

        case .typewriter:
            let full = cur
            let n = Int(Double(full.count) * min(1, progress * 1.8))
            ZStack(alignment: .topLeading) {
                Text(full).opacity(0)
                Text(String(full.prefix(n)) + (n < full.count ? "▍" : ""))
            }
            .font(s.f(34, .semibold)).multilineTextAlignment(.leading).padding(44)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

        case .poster:
            VStack(alignment: .leading, spacing: 10) {
                Text(text(index - 1)).font(s.f(18, .semibold)).opacity(0.3).lineLimit(1)
                FillText(text: cur.uppercased(), p: progress, on: s.accent, off: .white.opacity(0.9))
                    .font(s.f(70, .black)).minimumScaleFactor(0.3).lineLimit(3)
                Text(text(index + 1)).font(s.f(18, .semibold)).opacity(0.3).lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading).padding(44)

        case .bigWord:
            let ws = wordsOf(cur)
            let wi = min(max(ws.count - 1, 0), Int(progress * Double(ws.count)))
            let key = index * 1000 + wi
            let rot = jit(index, wi) * 14 * s.lean
            let dx = jit(wi, index + 5) * 90 * s.scatter
            let dy = jit(index + 9, wi) * 50 * s.scatter
            VStack(spacing: 18) {
                ZStack {
                    Text(ws.isEmpty ? "♪" : ws[wi])
                        .font(s.f(120, .black)).minimumScaleFactor(0.25).lineLimit(1)
                        .foregroundStyle(wi % 2 == 0 ? Color.white : s.accent)
                        .rotationEffect(.degrees(rot))
                        .offset(x: CGFloat(dx), y: CGFloat(dy))
                        .id(key).transition(.scale(scale: 0.55).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(duration: 0.22), value: key)
                Text(text(index)).font(s.f(14, .medium)).opacity(0.35).lineLimit(2).multilineTextAlignment(.center)
            }
            .padding(36)

        case .jumble:
            let ws = wordsOf(cur)
            let wi = min(max(ws.count - 1, 0), Int(progress * Double(ws.count)))
            ZStack {
                FlowLayout(spacing: 14) {
                    ForEach(Array(ws.enumerated()), id: \.offset) { i, w in
                        let size = 34 + 20 * (jit(index, i + 7) + 1) / 2
                        let rot = jit(index, i) * 14 * s.lean
                        let dx = jit(index, i + 30) * 26 * s.scatter
                        let dy = jit(index, i + 60) * 22 * s.scatter
                        Text(w).font(s.f(CGFloat(size), .black))
                            .foregroundStyle(i <= wi ? s.accent : Color.white.opacity(0.35))
                            .scaleEffect(i <= wi ? 1 : 0.85)
                            .rotationEffect(.degrees(rot))
                            .offset(x: CGFloat(dx), y: CGFloat(dy))
                    }
                }
                .padding(48)
                .id(index).transition(.opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(duration: 0.3), value: wi)
            .animation(.easeInOut(duration: 0.3), value: index)

        case .metric:
            let total = lines.count
            let nextIn = index + 1 < total ? String(format: "%.1fs", max(0, lines[index + 1].time - pos)) : "—"
            let wps = index >= 0 ? Double(wordsOf(cur).count) / max(0.1, lineDur) : 0
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 28) {
                    metric("LINE", "\(max(index + 1, 0))/\(total)")
                    metric("TIME", fmtTime(pos))
                    metric("W/S", String(format: "%.1f", wps))
                    metric("NEXT", nextIn)
                }
                Spacer()
                Text(cur).font(s.f(40)).minimumScaleFactor(0.4).id(index).transition(.opacity)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.15))
                        Rectangle().fill(s.accent).frame(width: g.size.width * progress)
                    }
                }
                .frame(height: 3)
                Text(text(index + 1)).font(s.f(18, .medium)).opacity(0.35).lineLimit(1)
                Spacer()
            }
            .padding(44)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 0.25), value: index)
        }
    }
}

struct StarShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let big = min(r.width, r.height) / 2
        let small = big * 0.16
        for i in 0..<8 {
            let a = Double(i) * .pi / 4 - .pi / 2
            let rad = i % 2 == 0 ? big : small
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * rad, y: c.y + CGFloat(sin(a)) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct ConstToken: View {
    let t: Constellation.Tok
    let p: CGPoint
    let s: LStyle
    var body: some View {
        ZStack {
            if t.current {
                Circle().stroke(s.accent.opacity(0.7), lineWidth: 1.5).frame(width: 64, height: 64).position(p)
            }
            StarShape().fill(Color.white.opacity(0.9))
                .frame(width: t.current ? 24 : 12, height: t.current ? 24 : 12)
                .shadow(color: s.accent, radius: 6).position(p)
            Text(t.text)
                .font(s.f(t.current ? 84 : 14 + 26 * CGFloat(t.d * t.d), .bold))
                .foregroundStyle(s.accent.opacity(t.current ? 1 : 0.5 + 0.4 * t.d))
                .blur(radius: t.current ? 0 : CGFloat((1 - t.d) * 2))
                .shadow(color: t.current ? s.accent.opacity(0.8) : .clear, radius: 14)
                .fixedSize()
                .position(x: p.x + 6, y: p.y + (t.current ? 58 : 22))
        }
        .transition(.opacity.combined(with: .scale(scale: 0.7)))
    }
}

/// Needle-style "Stars": words drift in as stars joined by thin constellation lines.
struct Constellation: View {
    struct Tok: Identifiable { let id: Int; let text: String; let x: Double; let y: Double; let d: Double; let current: Bool }
    let toks: [Tok]
    let s: LStyle

    var body: some View {
        GeometryReader { g in
            let pts = toks.map { CGPoint(x: $0.x * g.size.width, y: $0.y * g.size.height) }
            ZStack {
                Canvas { c, _ in
                    for i in 1..<max(pts.count, 1) {
                        var a = Path(); a.move(to: pts[i - 1]); a.addLine(to: pts[i])
                        c.stroke(a, with: .color(s.accent.opacity(0.45)), lineWidth: 1.2)
                        if i >= 2 {
                            var b = Path(); b.move(to: pts[i - 2]); b.addLine(to: pts[i])
                            c.stroke(b, with: .color(s.accent.opacity(0.2)), lineWidth: 1)
                        }
                    }
                }
                ForEach(Array(toks.enumerated()), id: \.element.id) { i, t in
                    ConstToken(t: t, p: pts[i], s: s)
                }
            }
        }
    }
}

/// Wrapping, centred layout used by the Jumble theme.
struct FlowLayout: Layout {
    var spacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 600
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, w: CGFloat = 0
        for v in subviews {
            let sz = v.sizeThatFits(.unspecified)
            if x + sz.width > maxW && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
            w = max(w, x - spacing)
        }
        return CGSize(width: w, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows: [[(LayoutSubview, CGSize)]] = [[]]
        var rowW: [CGFloat] = [0]
        for v in subviews {
            let sz = v.sizeThatFits(.unspecified)
            if rowW[rowW.count - 1] + sz.width > bounds.width && !rows[rows.count - 1].isEmpty {
                rows.append([]); rowW.append(0)
            }
            rows[rows.count - 1].append((v, sz))
            rowW[rowW.count - 1] += sz.width + spacing
        }
        var y = bounds.minY
        for (ri, row) in rows.enumerated() {
            let rw = rowW[ri] - spacing
            var x = bounds.minX + (bounds.width - rw) / 2
            let h = row.map { $0.1.height }.max() ?? 0
            for (v, sz) in row {
                v.place(at: CGPoint(x: x, y: y + (h - sz.height) / 2), proposal: ProposedViewSize(sz))
                x += sz.width + spacing
            }
            y += h + spacing
        }
    }
}

struct LyricsView: View {
    @ObservedObject var lyrics = LyricsStore.shared
    @ObservedObject var np = NowPlaying.shared
    @AppStorage(K.theme) private var themeRaw = LyricTheme.bigWord.rawValue
    @AppStorage(K.background) private var bg = "auto"
    @AppStorage(K.font) private var fontStyle = "rounded"
    @AppStorage(K.align) private var alignKey = "center"
    @AppStorage(K.scale) private var scale = 1.0
    @AppStorage(K.upper) private var upper = false
    @AppStorage(K.accent) private var accent = "cover"
    @AppStorage(K.scatter) private var scatter = 0.5
    @AppStorage(K.lean) private var lean = 0.5
    @AppStorage(K.mode) private var mode = "island"

    var theme: LyricTheme { LyricTheme(rawValue: themeRaw) ?? .bigWords }
    var style: LStyle {
        LStyle(font: fontStyle, scale: scale, align: alignKey == "left" ? .leading : .center,
               upper: upper, accent: verseAccent(accent, np.colors), colors: np.colors,
               scatter: scatter, lean: lean)
    }

    var body: some View {
        ZStack {
            if mode != "desktop" { ThemeBackground(theme: theme, setting: bg, colors: np.colors, art: np.artwork) }
            content
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(mode == "desktop" ? 0.6 : 0), radius: 8)
    }

    @ViewBuilder var content: some View {
        switch lyrics.state {
        case .idle: message(np.track == nil ? "Play a song in Spotify or Apple Music" : "")
        case .loading: message("Finding lyrics…")
        case .none: message("No lyrics found for this song")
        case .plain(let text):
            ScrollView {
                Text(text).font(style.f(20, .medium)).multilineTextAlignment(.center).padding(40)
            }
        case .synced(let lines):
            TimelineView(.periodic(from: .now, by: 0.05)) { ctx in
                let pos = np.position(at: ctx.date) + lyrics.totalOffset
                SyncedLyrics(theme: theme, lines: lines, index: lineIndex(lines, pos), pos: pos, s: style)
            }
        }
    }

    func message(_ s: String) -> some View {
        Text(s).font(.system(size: 18, weight: .medium)).foregroundStyle(.white.opacity(0.6))
    }
}

struct LyricsContainer: View {
    let rounded: Bool
    @ObservedObject var lyrics = LyricsStore.shared
    @AppStorage(K.mode) private var mode = "island"
    @AppStorage(K.theme) private var theme = LyricTheme.bigWord.rawValue

    var body: some View {
        LyricsView()
            .clipShape(RoundedRectangle(cornerRadius: rounded ? 28 : 0, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if mode != "desktop" {
                    HStack(spacing: 12) {
                        Button("−1") { lyrics.nudge(-1) }
                        Button("−.1") { lyrics.nudge(-0.1) }
                        Text(String(format: "%+.1fs", lyrics.offset)).font(.system(size: 11).monospacedDigit())
                        Button("+.1") { lyrics.nudge(0.1) }
                        Button("+1") { lyrics.nudge(1) }
                        Button { cycleTheme() } label: { Image(systemName: "paintpalette") }
                        Button { Sharing.copyCard() } label: { Image(systemName: "photo.on.rectangle") }
                        Button { mode = "island" } label: { Image(systemName: "chevron.up.circle") }
                    }
                    .buttonStyle(.plain).foregroundStyle(.white.opacity(0.75)).font(.system(size: 15))
                    .padding(14)
                }
            }
    }

    func cycleTheme() {
        let all = LyricTheme.allCases
        let cur = all.firstIndex { $0.rawValue == theme } ?? 0
        theme = all[(cur + 1) % all.count].rawValue
    }
}
