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
    var tint: Color = .purple
    var secondary: Color = .blue
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !animated)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            Canvas { c, size in
                // 1. Cosmic Deep Space Background
                let bgRect = CGRect(origin: .zero, size: size)
                let spaceGrad = Gradient(stops: [
                    .init(color: Color(red: 0.03, green: 0.04, blue: 0.10), location: 0),
                    .init(color: Color(red: 0.015, green: 0.015, blue: 0.05), location: 0.65),
                    .init(color: Color(red: 0.008, green: 0.008, blue: 0.025), location: 1.0)
                ])
                c.fill(Path(bgRect), with: .linearGradient(spaceGrad, startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

                // 2. Soft Ambient Cosmic Nebula Glows
                let neb1X = size.width * (0.35 + 0.14 * sin(t * 0.05))
                let neb1Y = size.height * (0.45 + 0.12 * cos(t * 0.04))
                let r1 = max(size.width, size.height) * 0.45
                c.fill(Path(ellipseIn: CGRect(x: neb1X - r1, y: neb1Y - r1, width: r1 * 2, height: r1 * 2)),
                       with: .radialGradient(Gradient(colors: [tint.opacity(0.18), .clear]),
                                             center: CGPoint(x: neb1X, y: neb1Y), startRadius: 0, endRadius: r1))

                let neb2X = size.width * (0.68 + 0.12 * cos(t * 0.06))
                let neb2Y = size.height * (0.58 + 0.10 * sin(t * 0.05))
                let r2 = max(size.width, size.height) * 0.40
                c.fill(Path(ellipseIn: CGRect(x: neb2X - r2, y: neb2Y - r2, width: r2 * 2, height: r2 * 2)),
                       with: .radialGradient(Gradient(colors: [secondary.opacity(0.14), .clear]),
                                             center: CGPoint(x: neb2X, y: neb2Y), startRadius: 0, endRadius: r2))

                // 3. Multi-layer Twinkling Starfield
                for i in 0..<110 {
                    let a = Double((i * 7919) % 1000) / 1000.0
                    let b = Double((i * 104729) % 997) / 997.0
                    let speed = 0.4 + 1.2 * Double((i * 31) % 100) / 100.0
                    let phase = Double((i * 53) % 100) / 100.0 * .pi * 2
                    let tw = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * speed + phase))

                    let tier = i % 10
                    let r: CGFloat
                    let starColor: Color
                    if tier == 0 {
                        // Rare brighter star with subtle cross flare
                        r = 2.4
                        starColor = (i % 3 == 0 ? tint : Color.white)
                        let center = CGPoint(x: a * size.width, y: b * size.height)
                        let spike = r * 2.8 * CGFloat(tw)
                        var hPath = Path(); hPath.move(to: CGPoint(x: center.x - spike, y: center.y)); hPath.addLine(to: CGPoint(x: center.x + spike, y: center.y))
                        var vPath = Path(); vPath.move(to: CGPoint(x: center.x, y: center.y - spike)); vPath.addLine(to: CGPoint(x: center.x, y: center.y + spike))
                        c.stroke(hPath, with: .color(starColor.opacity(0.4 * tw)), lineWidth: 0.8)
                        c.stroke(vPath, with: .color(starColor.opacity(0.4 * tw)), lineWidth: 0.8)
                    } else if tier < 4 {
                        r = 1.6
                        starColor = (i % 4 == 0 ? secondary : Color.white)
                    } else {
                        r = 0.95
                        starColor = Color(white: 0.92)
                    }

                    let rect = CGRect(x: a * size.width - r, y: b * size.height - r, width: r * 2, height: r * 2)
                    c.fill(Path(ellipseIn: rect), with: .color(starColor.opacity(tw)))
                }

                // 4. Occasional Shooting Star (Meteor)
                let meteorCycle = t.truncatingRemainder(dividingBy: 14.0)
                if animated && meteorCycle < 0.85 {
                    let mp = meteorCycle / 0.85
                    let sx = size.width * 0.15 + (size.width * 0.70) * CGFloat(mp)
                    let sy = size.height * 0.08 + (size.height * 0.42) * CGFloat(mp)
                    let trailLen: CGFloat = 85.0
                    let tailX = sx - trailLen * 0.85
                    let tailY = sy - trailLen * 0.53
                    var meteorPath = Path()
                    meteorPath.move(to: CGPoint(x: tailX, y: tailY))
                    meteorPath.addLine(to: CGPoint(x: sx, y: sy))
                    c.stroke(meteorPath,
                             with: .linearGradient(Gradient(colors: [.clear, Color.white.opacity(Double(1.0 - mp * 0.4))]),
                                                   startPoint: CGPoint(x: tailX, y: tailY),
                                                   endPoint: CGPoint(x: sx, y: sy)),
                             lineWidth: 1.5)
                    c.fill(Path(ellipseIn: CGRect(x: sx - 2, y: sy - 2, width: 4, height: 4)),
                           with: .color(Color.white.opacity(Double(1.0 - mp * 0.5))))
                }
            }
        }
    }
}

struct ThemeBackground: View {
    let theme: LyricTheme
    let setting: String
    let colors: [Color]
    let art: NSImage?
    var animated = true

    var body: some View {
        switch setting {
        case "black" where theme != .stars: Color.black
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
        case .wave: LinearGradient(colors: [c1.opacity(0.6), c0.opacity(0.25), .black], startPoint: .top, endPoint: .bottom)
        case .pop: ZStack { Color(white: 0.07); c2.opacity(0.18) }
        case .echo: RadialGradient(colors: [c0.opacity(0.45), .black], center: .center, startRadius: 0, endRadius: 420)
        case .cinema: Color.black
        case .liquid: Color.black
        case .synthwave: Color.black
        case .vinyl: LinearGradient(colors: [c0.opacity(0.45), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .glitch: Color(white: 0.04)
        case .orbit: RadialGradient(colors: [c1.opacity(0.4), .black], center: .center, startRadius: 0, endRadius: 460)
        case .bigWords: LinearGradient(colors: [.black, Color(white: 0.12)], startPoint: .top, endPoint: .bottom)
        case .karaoke: LinearGradient(colors: [c0.opacity(0.9), c2.opacity(0.7), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neon, .terminal: Color.black
        case .minimal: ZStack { Color.black.opacity(0.35); Rectangle().fill(.ultraThinMaterial) }
        case .lens: LinearGradient(colors: [c1.opacity(0.55), .black], startPoint: .top, endPoint: .bottom)
        case .typewriter: Color(white: 0.08)
        case .poster: ZStack { Color.black; c0.opacity(0.3) }
        case .stars: StarField(tint: c0, secondary: c1, animated: animated)
        case .aura where !animated:
            ZStack {
                Color.black
                Circle().fill(c0).frame(width: 200, height: 200).offset(x: -60)
                Circle().fill(c1).frame(width: 200, height: 200).offset(x: 60, y: 30)
            }.blur(radius: 30)
        case .aura:
            TimelineView(.animation(minimumInterval: 1.0 / 20)) { ctx in
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
    var animated = true

    func text(_ i: Int) -> String {
        guard i >= 0, i < lines.count else { return "" }
        return s.t(lines[i].text)
    }
    var cur: String { index < 0 ? "♪" : text(index) }
    var glitchAge: Double {
        guard index >= 0, index < lines.count else { return 9 }
        return max(0, pos - lines[index].time)
    }
    var progress: Double {
        guard index >= 0, index < lines.count else { return 0 }
        let start = lines[index].time
        let end = index + 1 < lines.count ? lines[index + 1].time : start + 5
        return min(1, max(0, (pos - start) / max(0.5, min(end - start, 8) * 0.9)))
    }

    /// Words of the last three lines become stars, spread over the whole screen with a
    /// low-discrepancy sequence so they never clump and stay put as the lines scroll.
    func starToks(_ wi: Int) -> [Constellation.Tok] {
        var out: [Constellation.Tok] = []
        guard index >= 0, index < lines.count else { return out }
        let spread = 0.6 + 0.4 * s.scatter
        for L in max(0, index - 2)...index {
            for (k, w) in wordsOf(lines[L].text).enumerated() {
                if L == index && k > wi { break }
                let n = Double(L * 16 + k + 1)
                let rx = (0.5 + n * 0.7548776662466927).truncatingRemainder(dividingBy: 1)
                let ry = (0.5 + n * 0.5698402909980532).truncatingRemainder(dividingBy: 1)
                out.append(Constellation.Tok(id: L * 1000 + k, text: w,
                                             x: 0.08 + 0.84 * (0.5 + (rx - 0.5) * spread),
                                             y: 0.10 + 0.80 * (0.5 + (ry - 0.5) * spread),
                                             d: (jit(L + 5, k + 9) + 1) / 2, age: index - L,
                                             current: L == index && k == wi))
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
            Constellation(lines: lines, index: index, pos: pos, s: s, animated: animated)

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

        case .wave:
            let ws = wordsOf(cur)
            let wi = min(max(ws.count - 1, 0), Int(progress * Double(ws.count)))
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated)) { ctx in
                let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
                ZStack {
                    WaveBackdrop(colors: s.colors, t: t)
                    FlowLayout(spacing: 16) {
                        ForEach(Array(ws.enumerated()), id: \.offset) { i, w in
                            let bobPhase = t * 3 + Double(i) * 0.8
                            let bobAmp = 12 * (0.4 + s.scatter)
                            let bob = CGFloat(sin(bobPhase) * bobAmp)
                            let lit = i <= wi
                            Text(w).font(s.f(52, .heavy))
                                .foregroundStyle(lit ? Color.white : Color.white.opacity(0.4))
                                .shadow(color: lit ? s.accent.opacity(0.8) : Color.clear, radius: 10)
                                .scaleEffect(i == wi ? 1.12 : 1)
                                .offset(y: bob)
                        }
                    }
                    .padding(.horizontal, 40).padding(.bottom, 60)
                    .animation(.spring(duration: 0.25), value: wi)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .pop:
            let ws = wordsOf(cur)
            FlowLayout(spacing: 12) {
                ForEach(Array(ws.enumerated()), id: \.offset) { i, w in
                    let wp = progress * Double(ws.count) - Double(i)
                    let on = wp > 0
                    let burst = CGFloat(min(max(wp, 0), 1))
                    let pill: Color = on ? s.c(i) : Color.white.opacity(0.06)
                    let textColor: Color = on ? Color.white : Color.white.opacity(0.3)
                    let popScale: CGFloat = on ? 1 + 0.2 * (1 - burst) : 0.92
                    let glowColor: Color = on ? s.c(i).opacity(0.6) : Color.clear
                    let outline: Double = on ? 0 : 0.2
                    Text(w).font(s.f(38, .black))
                        .foregroundStyle(textColor)
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(pill, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(outline), lineWidth: 1))
                        .background {
                            if on {
                                Capsule().stroke(s.c(i).opacity(Double(1 - burst)), lineWidth: 3)
                                    .scaleEffect(1 + burst * 0.8)
                            }
                        }
                        .scaleEffect(popScale)
                        .shadow(color: glowColor, radius: 12)
                }
            }
            .padding(40).frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(index)

        case .echo:
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated)) { ctx in
                let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
                ZStack {
                    Canvas { c, sz in
                        let ctr = CGPoint(x: sz.width / 2, y: sz.height / 2)
                        let maxR = max(sz.width, sz.height) * 0.6
                        for k in 0..<6 {
                            let maxD = Double(maxR)
                            let travel = t * 45 + Double(k) * maxD / 6
                            let r = CGFloat(travel.truncatingRemainder(dividingBy: maxD))
                            let a = 1 - Double(r / maxR)
                            c.stroke(Path(ellipseIn: CGRect(x: ctr.x - r, y: ctr.y - r * 0.55, width: 2 * r, height: 1.1 * r)),
                                     with: .color(s.c(k).opacity(0.35 * a)), lineWidth: 1.5)
                        }
                    }
                    ZStack {
                        ForEach(0..<4, id: \.self) { i in
                            let layer = 3 - i
                            Text(cur).font(s.f(54, .black)).multilineTextAlignment(s.align).minimumScaleFactor(0.3)
                                .foregroundStyle(layer == 0 ? Color.white : s.c(layer).opacity(0.55 - 0.12 * Double(layer)))
                                .scaleEffect(1 + 0.12 * CGFloat(layer))
                                .blur(radius: CGFloat(layer))
                        }
                    }
                    .padding(48).id(index).transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.35), value: index)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .cinema:
            GeometryReader { g in
                let bar = g.size.height * 0.11
                ZStack {
                    LinearGradient(colors: [s.c(0).opacity(0.22), .clear, s.c(2).opacity(0.18)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    RadialGradient(colors: [.clear, Color.black.opacity(0.65)], center: .center,
                                   startRadius: g.size.width * 0.25, endRadius: g.size.width * 0.75)
                    VStack(spacing: 0) {
                        Color.black.frame(height: bar)
                            .overlay {
                                HStack { Text("VERSE").tracking(4); Spacer(); Text(fmtTime(pos)) }
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.45)).padding(.horizontal, 22)
                            }
                        Spacer()
                        Color.black.frame(height: bar)
                            .overlay {
                                HStack { Text("LINE \(max(index + 1, 0)) / \(lines.count)"); Spacer(); Text(String(format: "%.0f%%", progress * 100)) }
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.45)).padding(.horizontal, 22)
                            }
                    }
                    VStack(spacing: 8) {
                        Text(text(index - 1)).font(s.f(15, .regular).italic()).opacity(0.35).lineLimit(1)
                        Text(cur).font(s.f(30, .medium).italic())
                    }
                    .multilineTextAlignment(.center).minimumScaleFactor(0.4)
                    .shadow(color: .black, radius: 3)
                    .padding(.horizontal, 40)
                    .position(x: g.size.width / 2, y: g.size.height * 0.74)
                    .id(index).transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.3), value: index)
            }

        case .liquid:
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated)) { ctx in
                let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
                let sway = 0.5 * sin(t * 0.7)
                let fillGrad = LinearGradient(colors: [s.c(0), Color.white, s.c(1), s.c(2)],
                                              startPoint: UnitPoint(x: 0.5 + sway, y: 0),
                                              endPoint: UnitPoint(x: 0.5 - sway, y: 1))
                ZStack {
                    Canvas { c, sz in
                        for j in 0..<3 {
                            let jd = Double(j)
                            let ph = t * (0.25 + jd * 0.11) + jd * 2.1
                            let fx = 0.5 + 0.35 * CGFloat(sin(ph))
                            let fy = 0.5 + 0.3 * CGFloat(cos(ph * 1.3))
                            let ctr = CGPoint(x: sz.width * fx, y: sz.height * fy)
                            let r = sz.width * 0.45
                            c.fill(Path(ellipseIn: CGRect(x: ctr.x - r, y: ctr.y - r, width: 2 * r, height: 2 * r)),
                                   with: .radialGradient(Gradient(colors: [s.c(j).opacity(0.75), .clear]),
                                                         center: ctr, startRadius: 0, endRadius: r))
                        }
                    }
                    Text(cur).font(s.f(66, .black)).multilineTextAlignment(s.align).minimumScaleFactor(0.3)
                        .padding(48)
                        .foregroundStyle(fillGrad)
                        .id(index).transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.4), value: index)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .synthwave:
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated)) { ctx in
                let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
                ZStack {
                    Canvas { c, sz in
                        let hz = sz.height * 0.58
                        c.fill(Path(CGRect(x: 0, y: 0, width: sz.width, height: hz)),
                               with: .linearGradient(Gradient(colors: [Color(red: 0.08, green: 0, blue: 0.2), Color(red: 0.9, green: 0.2, blue: 0.6)]),
                                                     startPoint: .zero, endPoint: CGPoint(x: 0, y: hz)))
                        let sr = sz.height * 0.2
                        let sc = CGPoint(x: sz.width / 2, y: hz - sr * 0.3)
                        c.drawLayer { l in
                            l.clip(to: Path(CGRect(x: 0, y: 0, width: sz.width, height: hz)))
                            l.fill(Path(ellipseIn: CGRect(x: sc.x - sr, y: sc.y - sr, width: 2 * sr, height: 2 * sr)),
                                   with: .linearGradient(Gradient(colors: [Color.yellow, Color.orange, Color(red: 1, green: 0.2, blue: 0.5)]),
                                                         startPoint: CGPoint(x: 0, y: sc.y - sr), endPoint: CGPoint(x: 0, y: sc.y + sr)))
                        }
                        c.fill(Path(CGRect(x: 0, y: hz, width: sz.width, height: sz.height - hz)),
                               with: .color(Color(red: 0.05, green: 0, blue: 0.12)))
                        let grid = Color(red: 0.2, green: 0.9, blue: 1)
                        let shift = (t * 0.5).truncatingRemainder(dividingBy: 1)
                        for i in 0..<10 {
                            let f = (Double(i) + shift) / 10
                            let y = hz + (sz.height - hz) * CGFloat(f * f)
                            var p = Path()
                            p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: sz.width, y: y))
                            c.stroke(p, with: .color(grid.opacity(0.2 + 0.6 * f)), lineWidth: 1)
                        }
                        for i in -8...8 {
                            var p = Path()
                            p.move(to: CGPoint(x: sz.width / 2, y: hz))
                            p.addLine(to: CGPoint(x: sz.width / 2 + CGFloat(i) * sz.width * 0.14, y: sz.height))
                            c.stroke(p, with: .color(grid.opacity(0.5)), lineWidth: 1)
                        }
                    }
                    Text(cur).font(s.f(44, .heavy).italic()).multilineTextAlignment(.center).minimumScaleFactor(0.3)
                        .foregroundStyle(LinearGradient(colors: [Color(red: 1, green: 0.4, blue: 0.8), Color(red: 0.4, green: 0.9, blue: 1)],
                                                        startPoint: .top, endPoint: .bottom))
                        .shadow(color: Color(red: 1, green: 0.2, blue: 0.6).opacity(0.8), radius: 12)
                        .padding(.horizontal, 40).padding(.top, 50)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .id(index).transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.3), value: index)
            }

        case .vinyl:
            HStack(spacing: 28) {
                RecordView(size: 190 * CGFloat(min(s.scale, 1.2)), animated: animated)
                VStack(alignment: .leading, spacing: 10) {
                    Text(text(index - 1)).font(s.f(16, .medium)).opacity(0.35).lineLimit(1)
                    Text(cur).font(s.f(38, .heavy)).minimumScaleFactor(0.4).id(index).transition(.opacity)
                    Text(text(index + 1)).font(s.f(16, .medium)).opacity(0.35).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(40)
            .animation(.easeInOut(duration: 0.3), value: index)

        case .glitch:
            let decay = max(0, 1 - glitchAge / 0.45)
            let spreadK = 0.4 + s.scatter
            let d = CGFloat(10 * decay * spreadK)
            let jy = CGFloat(jit(index, 3)) * d * 0.3
            ZStack {
                Text(cur).foregroundStyle(Color.red).offset(x: d, y: jy).blendMode(.screen)
                Text(cur).foregroundStyle(Color.cyan).offset(x: -d, y: -jy).blendMode(.screen)
                Text(cur).foregroundStyle(Color.white)
                Canvas { c, sz in
                    var y: CGFloat = 0
                    while y < sz.height {
                        c.fill(Path(CGRect(x: 0, y: y, width: sz.width, height: 1)), with: .color(Color.black.opacity(0.22)))
                        y += 4
                    }
                }
                .allowsHitTesting(false)
            }
            .font(s.f(58, .black)).multilineTextAlignment(s.align).minimumScaleFactor(0.3).padding(48)

        case .orbit:
            let ws = wordsOf(cur)
            let wi = min(max(ws.count - 1, 0), Int(progress * Double(ws.count)))
            GeometryReader { g in
                let n = max(ws.count, 1)
                ZStack {
                    Ellipse().stroke(Color.white.opacity(0.08), lineWidth: 1)
                        .frame(width: g.size.width * 0.68, height: g.size.height * 0.28)
                        .position(x: g.size.width / 2, y: g.size.height * 0.58)
                    ForEach(Array(ws.enumerated()), id: \.offset) { i, w in
                        let step = 2 * Double.pi / Double(n)
                        let a = Double.pi / 2 + Double(i - wi) * step
                        let depth = (sin(a) + 1) / 2
                        let ox = CGFloat(cos(a)) * g.size.width * 0.34
                        let oy = CGFloat(sin(a)) * g.size.height * 0.14
                        Text(w).font(s.f(40, .heavy))
                            .foregroundStyle(i == wi ? s.accent : Color.white)
                            .scaleEffect(0.55 + 0.6 * CGFloat(depth))
                            .opacity(0.25 + 0.75 * depth)
                            .blur(radius: CGFloat((1 - depth) * 2))
                            .position(x: g.size.width / 2 + ox, y: g.size.height * 0.58 + oy)
                            .zIndex(depth)
                    }
                }
                .animation(.spring(duration: 0.55), value: wi)
            }
            .id(index)
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

/// Needle-style "Stars": fluid celestial constellation where lyrics illuminate as glowing stars
/// scattered in 2D space across the entire screen. The current sung word ignites as a brilliant
/// celestial beacon with diffraction flares, breathing auras, and expanding gravitational pulse rings.
struct Constellation: View, Equatable {
    struct Tok: Identifiable, Equatable {
        let id: Int; let text: String; let x: Double; let y: Double
        let d: Double; let age: Int; let current: Bool
    }

    var lines: [LyricLine] = []
    var index: Int = -1
    var pos: Double = 0
    var s: LStyle
    var animated: Bool = true
    var toks: [Tok] = []

    init(lines: [LyricLine], index: Int, pos: Double, s: LStyle, animated: Bool = true) {
        self.lines = lines
        self.index = index
        self.pos = pos
        self.s = s
        self.animated = animated
        self.toks = []
    }

    init(toks: [Tok], s: LStyle, animated: Bool = true) {
        self.lines = []
        self.index = -1
        self.pos = 0
        self.s = s
        self.animated = animated
        self.toks = toks
    }

    static func == (a: Constellation, b: Constellation) -> Bool {
        a.index == b.index && abs(a.pos - b.pos) < 0.005 && a.s.accent == b.s.accent && a.s.font == b.s.font && a.s.scale == b.s.scale && a.animated == b.animated
    }

    private func wordsOf(_ t: String) -> [String] {
        t.split(separator: " ").map(String.init)
    }

    private func jit(_ a: Int, _ b: Int) -> Double {
        let x = sin(Double(a) * 12.9898 + Double(b) * 78.233) * 43758.5453
        return (x - x.rounded(.down)) * 2 - 1
    }

    var body: some View {
        let k_scale = s.scale < 0.4 ? 0.7 : s.scale
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !animated)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : pos
            Canvas { c, sz in
                // 1. Ambient celestial micro-stars (ensures depth across all backgrounds and desktop mode)
                for i in 0..<36 {
                    let ax = Double((i * 4919) % 1000) / 1000.0
                    let ay = Double((i * 84729) % 997) / 997.0
                    let spd = 0.8 + 1.2 * Double((i * 37) % 50) / 50.0
                    let ph = Double((i * 71) % 100) / 100.0 * .pi * 2
                    let tw = 0.2 + 0.8 * (0.5 + 0.5 * sin(t * spd + ph))
                    let r: CGFloat = (i % 5 == 0) ? 1.6 : 1.0
                    c.fill(Path(ellipseIn: CGRect(x: ax * sz.width - r, y: ay * sz.height - r, width: r * 2, height: r * 2)),
                           with: .color(Color.white.opacity(tw * 0.5)))
                }

                // If fallback toks provided and no lines
                if lines.isEmpty && !toks.isEmpty {
                    renderLegacyToks(c: c, sz: sz, t: t, k_scale: k_scale)
                    return
                }

                // Empty / idle state
                guard index >= 0, index < lines.count else {
                    let center = CGPoint(x: sz.width * 0.5, y: sz.height * 0.5)
                    let pulse = 0.5 + 0.5 * sin(t * 2.5)
                    let r = (20 + 8 * CGFloat(pulse)) * CGFloat(k_scale)
                    c.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                             with: .color(s.accent.opacity(0.35 + 0.4 * pulse)), lineWidth: 1.5)
                    c.fill(Path(ellipseIn: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)),
                           with: .color(Color.white.opacity(0.9)))
                    let label = Text("♪").font(verseFont(s.font, 28 * CGFloat(k_scale), .bold)).foregroundColor(s.accent)
                    c.draw(label, at: CGPoint(x: center.x, y: center.y + 24 * CGFloat(k_scale)), anchor: .top)
                    return
                }

                // Active line calculations
                let curLine = lines[index]
                let nextTime = index + 1 < lines.count ? lines[index + 1].time : curLine.time + 4.5
                let lineDur = max(0.6, nextTime - curLine.time)
                let elapsed = max(0, pos - curLine.time)
                let lineProg = min(1.0, max(0.0, elapsed / (lineDur * 0.95)))

                let curWords = wordsOf(curLine.text)
                let N = max(1, curWords.count)
                let wordPos = lineProg * Double(N)
                let curWordIdx = min(N - 1, max(0, Int(wordPos)))
                let wordFraction = wordPos - Double(curWordIdx)

                // Build 2D scattered constellation stars (non-linear low-discrepancy distribution)
                let spread = 0.6 + 0.4 * s.scatter
                struct StarNode {
                    let id: Int
                    let text: String
                    let pt: CGPoint
                    let d: Double
                    let age: Int
                    let isCurrent: Bool
                }

                var stars: [StarNode] = []
                let startLine = max(0, index - 2)
                if startLine <= index {
                    for L in startLine...index {
                        let ws = wordsOf(lines[L].text)
                        for (k, w) in ws.enumerated() {
                            if L == index && k > curWordIdx { break }
                            let n = Double(L * 16 + k + 1)
                            let rx = (0.5 + n * 0.7548776662466927).truncatingRemainder(dividingBy: 1)
                            let ry = (0.5 + n * 0.5698402909980532).truncatingRemainder(dividingBy: 1)
                            let nx = 0.08 + 0.84 * (0.5 + (rx - 0.5) * spread)
                            let ny = 0.10 + 0.80 * (0.5 + (ry - 0.5) * spread)
                            let pt = CGPoint(x: nx * sz.width, y: ny * sz.height)
                            let dVal = (jit(L + 5, k + 9) + 1) / 2
                            stars.append(StarNode(id: L * 1000 + k, text: w, pt: pt, d: dVal, age: index - L, isCurrent: (L == index && k == curWordIdx)))
                        }
                    }
                }

                guard !stars.isEmpty else { return }

                // 2. Draw Constellation Connecting Lines in 2D space
                if stars.count > 1 {
                    for i in 1..<stars.count {
                        let isLastSegment = (i == stars.count - 1 && stars[i].isCurrent)
                        let fade = max(0.1, 1.0 - 0.28 * Double(stars[i].age))

                        if isLastSegment {
                            // Actively drawing glowing energy beam to current word!
                            let drawP = min(1.0, max(0.0, wordFraction / 0.35))
                            let smoothDraw = drawP * drawP * (3.0 - 2.0 * drawP)
                            let p0 = stars[i - 1].pt
                            let p1 = stars[i].pt
                            let head = CGPoint(x: p0.x + (p1.x - p0.x) * CGFloat(smoothDraw),
                                               y: p0.y + (p1.y - p0.y) * CGFloat(smoothDraw))

                            var beam = Path(); beam.move(to: p0); beam.addLine(to: head)
                            // Outer beam glow
                            c.stroke(beam, with: .color(s.accent.opacity(0.40)), lineWidth: 3.5 * CGFloat(k_scale))
                            // Core beam
                            c.stroke(beam, with: .linearGradient(
                                Gradient(colors: [s.accent.opacity(0.8), Color.white.opacity(0.95)]),
                                startPoint: p0, endPoint: head), lineWidth: 1.6 * CGFloat(k_scale))

                            // Traveling photon spark
                            if smoothDraw < 0.98 {
                                c.fill(Path(ellipseIn: CGRect(x: head.x - 3.5, y: head.y - 3.5, width: 7, height: 7)),
                                       with: .color(Color.white))
                                c.fill(Path(ellipseIn: CGRect(x: head.x - 7, y: head.y - 7, width: 14, height: 14)),
                                       with: .color(s.accent.opacity(0.6)))
                            }

                            // Faint guide for the rest of this active segment
                            if smoothDraw < 1.0 {
                                var rem = Path(); rem.move(to: head); rem.addLine(to: p1)
                                c.stroke(rem, with: .color(Color.white.opacity(0.12)),
                                         style: StrokeStyle(lineWidth: 0.9 * CGFloat(k_scale), dash: [4, 4]))
                            }
                        } else {
                            // Completed previous line
                            var a = Path(); a.move(to: stars[i - 1].pt); a.addLine(to: stars[i].pt)
                            c.stroke(a, with: .color(s.accent.opacity(0.48 * fade)), lineWidth: 1.3 * CGFloat(k_scale))
                        }

                        // Constellation Triangulation Chords (2 and 3 stars back)
                        if i >= 2 {
                            var b = Path(); b.move(to: stars[i - 2].pt); b.addLine(to: stars[i].pt)
                            c.stroke(b, with: .color(s.accent.opacity(0.20 * fade)), lineWidth: 0.9 * CGFloat(k_scale))
                        }
                        if i >= 3 {
                            var dPath = Path(); dPath.move(to: stars[i - 3].pt); dPath.addLine(to: stars[i].pt)
                            c.stroke(dPath, with: .color(s.accent.opacity(0.11 * fade)), lineWidth: 0.7 * CGFloat(k_scale))
                        }
                    }
                }

                // 3. Draw Stars and Labels
                for star in stars {
                    let p = star.pt
                    let fade = max(0.1, 1.0 - 0.28 * Double(star.age))

                    if star.isCurrent {
                        // --- THE ACTIVE HERO STAR ---
                        let bloom = CGFloat(sin(t * 3.2) * 0.14 + 1.0)
                        let heroScale = CGFloat(k_scale) * bloom

                        // 1. Concentric Gravitational Pulse Waves
                        let ringPhase1 = (t * 1.8).truncatingRemainder(dividingBy: 1.0)
                        let r1 = (11.0 + 36.0 * CGFloat(ringPhase1)) * heroScale
                        let op1 = 0.75 * (1.0 - ringPhase1)
                        c.stroke(Path(ellipseIn: CGRect(x: p.x - r1, y: p.y - r1, width: r1 * 2, height: r1 * 2)),
                                 with: .color(s.accent.opacity(op1)), lineWidth: 1.5)

                        let ringPhase2 = (t * 1.8 + 0.5).truncatingRemainder(dividingBy: 1.0)
                        let r2 = (11.0 + 36.0 * CGFloat(ringPhase2)) * heroScale
                        let op2 = 0.50 * (1.0 - ringPhase2)
                        c.stroke(Path(ellipseIn: CGRect(x: p.x - r2, y: p.y - r2, width: r2 * 2, height: r2 * 2)),
                                 with: .color(s.accent.opacity(op2)), lineWidth: 1.2)

                        // 2. Multi-layer Stellar Aura
                        let haloR: CGFloat = 32.0 * heroScale
                        c.fill(Path(ellipseIn: CGRect(x: p.x - haloR, y: p.y - haloR, width: haloR * 2, height: haloR * 2)),
                               with: .radialGradient(Gradient(colors: [s.accent.opacity(0.35), .clear]),
                                                     center: p, startRadius: 0, endRadius: haloR))

                        let midR: CGFloat = 15.0 * heroScale
                        c.fill(Path(ellipseIn: CGRect(x: p.x - midR, y: p.y - midR, width: midR * 2, height: midR * 2)),
                               with: .color(s.accent.opacity(0.65)))

                        let coreR: CGFloat = 5.5 * heroScale
                        c.fill(Path(ellipseIn: CGRect(x: p.x - coreR, y: p.y - coreR, width: coreR * 2, height: coreR * 2)),
                               with: .color(Color.white.opacity(0.98)))

                        // 3. Diffraction Spikes (Celestial Cross Flare)
                        let spkLen: CGFloat = (26.0 + 4.0 * sin(t * 2.6)) * heroScale
                        let spkW: CGFloat = 1.8 * heroScale

                        var hSpk = Path()
                        hSpk.move(to: CGPoint(x: p.x - spkLen, y: p.y))
                        hSpk.addLine(to: CGPoint(x: p.x, y: p.y - spkW))
                        hSpk.addLine(to: CGPoint(x: p.x + spkLen, y: p.y))
                        hSpk.addLine(to: CGPoint(x: p.x, y: p.y + spkW))
                        hSpk.closeSubpath()
                        c.fill(hSpk, with: .color(Color.white.opacity(0.92)))

                        var vSpk = Path()
                        vSpk.move(to: CGPoint(x: p.x, y: p.y - spkLen))
                        vSpk.addLine(to: CGPoint(x: p.x - spkW, y: p.y))
                        vSpk.addLine(to: CGPoint(x: p.x, y: p.y + spkLen))
                        vSpk.addLine(to: CGPoint(x: p.x + spkW, y: p.y))
                        vSpk.closeSubpath()
                        c.fill(vSpk, with: .color(Color.white.opacity(0.92)))

                        let diagLen = spkLen * 0.44
                        let diagW = spkW * 0.75
                        let cos45 = CGFloat(0.7071)
                        let sin45 = CGFloat(0.7071)
                        var d1 = Path()
                        d1.move(to: CGPoint(x: p.x - diagLen * cos45, y: p.y - diagLen * sin45))
                        d1.addLine(to: CGPoint(x: p.x + diagW * sin45, y: p.y - diagW * cos45))
                        d1.addLine(to: CGPoint(x: p.x + diagLen * cos45, y: p.y + diagLen * sin45))
                        d1.addLine(to: CGPoint(x: p.x - diagW * sin45, y: p.y + diagW * cos45))
                        d1.closeSubpath()
                        c.fill(d1, with: .color(Color.white.opacity(0.55)))

                        var d2 = Path()
                        d2.move(to: CGPoint(x: p.x - diagLen * cos45, y: p.y + diagLen * sin45))
                        d2.addLine(to: CGPoint(x: p.x + diagW * sin45, y: p.y + diagW * cos45))
                        d2.addLine(to: CGPoint(x: p.x + diagLen * cos45, y: p.y - diagLen * sin45))
                        d2.addLine(to: CGPoint(x: p.x - diagW * sin45, y: p.y - diagW * cos45))
                        d2.closeSubpath()
                        c.fill(d2, with: .color(Color.white.opacity(0.55)))

                        // Label placement (intelligent boundary awareness)
                        let onRight = p.x < sz.width * 0.72
                        let r = 11.0 * heroScale
                        let at = CGPoint(x: p.x + (onRight ? r + 9 : -(r + 9)), y: p.y)
                        let anchor: UnitPoint = onRight ? .leading : .trailing

                        let fs = min(sz.height * 0.11, 44) * CGFloat(k_scale)
                        let label = Text(s.t(star.text)).font(verseFont(s.font, fs, .heavy)).foregroundColor(s.accent)
                        c.drawLayer { l in
                            l.addFilter(.shadow(color: Color.black.opacity(0.9), radius: 6))
                            l.addFilter(.shadow(color: s.accent.opacity(0.85), radius: 14))
                            l.draw(label, at: at, anchor: anchor)
                        }
                    } else {
                        // Past star in constellation
                        let r: CGFloat = (4.0 + 3.0 * CGFloat(star.d)) * CGFloat(k_scale)
                        c.fill(Path(ellipseIn: CGRect(x: p.x - r * 1.8, y: p.y - r * 1.8, width: r * 3.6, height: r * 3.6)),
                               with: .color(s.accent.opacity(0.20 * fade)))
                        c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2.0, height: r * 2.0)),
                               with: .color(Color.white.opacity(0.92 * fade)))

                        // Micro cross-flare for variety
                        if star.d > 0.4 {
                            let spk = r * 1.6
                            var cross = Path()
                            cross.move(to: CGPoint(x: p.x - spk, y: p.y)); cross.addLine(to: CGPoint(x: p.x + spk, y: p.y))
                            cross.move(to: CGPoint(x: p.x, y: p.y - spk)); cross.addLine(to: CGPoint(x: p.x, y: p.y + spk))
                            c.stroke(cross, with: .color(Color.white.opacity(0.35 * fade)), lineWidth: 0.8)
                        }

                        // Label placement
                        let onRight = p.x < sz.width * 0.72
                        let at = CGPoint(x: p.x + (onRight ? r + 7 : -(r + 7)), y: p.y)
                        let anchor: UnitPoint = onRight ? .leading : .trailing

                        let fs = (13 + 17 * CGFloat(star.d * star.d)) * CGFloat(k_scale)
                        let label = Text(s.t(star.text)).font(verseFont(s.font, fs, .bold))
                            .foregroundColor(s.accent.opacity((0.55 + 0.35 * star.d) * fade))
                        c.drawLayer { l in
                            l.addFilter(.shadow(color: Color.black.opacity(0.6), radius: 4))
                            l.draw(label, at: at, anchor: anchor)
                        }
                    }
                }
            }
        }
    }

    private func renderLegacyToks(c: GraphicsContext, sz: CGSize, t: Double, k_scale: Double) {
        let pts = toks.map { CGPoint(x: CGFloat($0.x) * sz.width, y: CGFloat($0.y) * sz.height) }
        if pts.count > 1 {
            for i in 1..<pts.count {
                let fade = 1.0 - 0.28 * Double(toks[i].age)
                var a = Path(); a.move(to: pts[i - 1]); a.addLine(to: pts[i])
                c.stroke(a, with: .color(s.accent.opacity(0.5 * fade)), lineWidth: 1.3)
            }
        }
        for (i, tok) in toks.enumerated() {
            let p = pts[i]
            let fade = 1.0 - 0.28 * Double(tok.age)
            let r: CGFloat = tok.current ? 10 : 4.5
            c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                   with: .color(Color.white.opacity(0.95 * fade)))
            let fs: CGFloat = (tok.current ? 34 : 16) * CGFloat(k_scale)
            let label = Text(s.t(tok.text)).font(verseFont(s.font, fs, tok.current ? .heavy : .bold))
                .foregroundColor(tok.current ? s.accent : Color.white.opacity(0.75 * fade))
            c.draw(label, at: CGPoint(x: p.x, y: p.y + (tok.current ? 22 : 14)), anchor: .top)
        }
    }
}

struct WaveBackdrop: View {
    var colors: [Color]
    var t: Double
    var body: some View {
        Canvas { c, sz in
            guard !colors.isEmpty else { return }
            for j in 0..<4 {
                var p = Path()
                let base = sz.height * (0.55 + 0.1 * CGFloat(j))
                let amp = 18.0 + 10.0 * Double(j)
                p.move(to: CGPoint(x: 0, y: sz.height))
                var x: CGFloat = 0
                while x <= sz.width + 8 {
                    let jd = Double(j)
                    let speed = 0.8 + jd * 0.35
                    let phase = t * speed + jd * 1.7
                    let wave = sin(Double(x) / 90.0 + phase) * amp
                    let y = base + CGFloat(wave)
                    p.addLine(to: CGPoint(x: x, y: y))
                    x += 8
                }
                p.addLine(to: CGPoint(x: sz.width, y: sz.height))
                p.closeSubpath()
                c.fill(p, with: .linearGradient(
                    Gradient(colors: [colors[j % colors.count].opacity(0.55), colors[(j + 1) % colors.count].opacity(0.1)]),
                    startPoint: CGPoint(x: 0, y: base), endPoint: CGPoint(x: 0, y: sz.height)))
            }
        }
        .allowsHitTesting(false)
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
    @AppStorage(K.artLyrics) private var artOn = true
    @AppStorage(K.artEffect) private var artEffect = "aura"
    @AppStorage(K.artDim) private var artDim = 0.45
    @AppStorage(K.mode) private var mode = "island"

    var theme: LyricTheme { LyricTheme(rawValue: themeRaw) ?? .bigWords }
    /// Fill-style themes need smooth progress; the rest only change per word/line.
    var tick: Double {
        let smooth: [LyricTheme] = [.karaoke, .poster, .typewriter, .metric, .pop, .glitch, .cinema, .stars]
        return smooth.contains(theme) ? 0.016 : 0.1
    }
    var style: LStyle {
        LStyle(font: fontStyle, scale: scale, align: alignKey == "left" ? .leading : .center,
               upper: upper, accent: verseAccent(accent, np.colors), colors: np.colors,
               scatter: scatter, lean: lean)
    }

    var body: some View {
        ZStack {
            if mode != "desktop" {
                ThemeBackground(theme: theme, setting: bg, colors: np.colors, art: np.artwork)
                if artOn {
                    ArtBackground(art: np.artwork, colors: np.colors, effect: artEffect, dim: artDim)
                        .transition(.opacity)
                }
            }
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
            TimelineView(.periodic(from: .now, by: tick)) { ctx in
                let pos = np.position(at: ctx.date) + lyrics.totalOffset
                SyncedLyrics(theme: theme, lines: lines, index: lineIndex(lines, pos), pos: pos, s: style)
            }
        }
    }

    func message(_ s: String) -> some View {
        Text(s).font(.system(size: 18, weight: .medium)).foregroundStyle(.white.opacity(0.6))
    }
}
