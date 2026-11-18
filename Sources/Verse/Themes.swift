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
        TimelineView(.animation(minimumInterval: PowerOptimizer.shared.animationInterval, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
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

struct CyberpunkBackground: View {
    var animated: Bool = true
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            Canvas { c, sz in
                // Deep dark cyber background
                c.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color(red: 0.035, green: 0.04, blue: 0.06)))

                // Grid lines
                let grid: CGFloat = 36
                var x: CGFloat = 0
                while x <= sz.width {
                    var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: sz.height))
                    c.stroke(p, with: .color(Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.04)), lineWidth: 1)
                    x += grid
                }
                var y: CGFloat = 0
                while y <= sz.height {
                    var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: sz.width, y: y))
                    c.stroke(p, with: .color(Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.04)), lineWidth: 1)
                    y += grid
                }

                // Laser scanline sweeping vertically
                let scanY = (t * 80).truncatingRemainder(dividingBy: sz.height)
                var scanPath = Path()
                scanPath.move(to: CGPoint(x: 0, y: scanY))
                scanPath.addLine(to: CGPoint(x: sz.width, y: scanY))
                c.stroke(scanPath, with: .color(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.18)), lineWidth: 1.5)

                // Corner HUD brackets
                let bLen: CGFloat = 20
                for pt in [CGPoint(x: 16, y: 16), CGPoint(x: sz.width - 16, y: 16), CGPoint(x: 16, y: sz.height - 16), CGPoint(x: sz.width - 16, y: sz.height - 16)] {
                    var b = Path()
                    let dx: CGFloat = pt.x < 100 ? bLen : -bLen
                    let dy: CGFloat = pt.y < 100 ? bLen : -bLen
                    b.move(to: CGPoint(x: pt.x, y: pt.y + dy))
                    b.addLine(to: pt)
                    b.addLine(to: CGPoint(x: pt.x + dx, y: pt.y))
                    c.stroke(b, with: .color(Color(red: 1.0, green: 0.0, blue: 0.4).opacity(0.5)), lineWidth: 1.5)
                }
            }
        }
    }
}

struct QuantumBackground: View {
    var tint: Color = .purple
    var secondary: Color = .blue
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: PowerOptimizer.shared.animationInterval, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            Canvas { c, sz in
                c.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color(red: 0.02, green: 0.025, blue: 0.05)))

                let center = CGPoint(x: sz.width / 2, y: sz.height / 2)
                let baseR = min(sz.width, sz.height) * 0.38

                // Rotating quantum orbital probability rings
                for i in 0..<3 {
                    let angle = t * (0.3 + Double(i) * 0.15) * (i % 2 == 0 ? 1 : -1)
                    let scaleX = 1.0 - Double(i) * 0.22
                    let scaleY = 0.35 + Double(i) * 0.18

                    c.drawLayer { l in
                        l.translateBy(x: center.x, y: center.y)
                        l.rotate(by: .radians(angle + Double(i) * .pi / 3))
                        let rect = CGRect(x: -baseR * scaleX, y: -baseR * scaleY, width: baseR * 2 * scaleX, height: baseR * 2 * scaleY)
                        let ringColor = (i == 0 ? tint : (i == 1 ? secondary : Color.cyan)).opacity(0.25)
                        l.stroke(Path(ellipseIn: rect), with: .color(ringColor), lineWidth: 1.2)

                        // Subatomic particle node revolving on ring
                        let pAngle = t * 1.8 + Double(i) * 2.0
                        let px = cos(pAngle) * baseR * scaleX
                        let py = sin(pAngle) * baseR * scaleY
                        l.fill(Path(ellipseIn: CGRect(x: px - 3, y: py - 3, width: 6, height: 6)), with: .color(Color.white.opacity(0.85)))
                    }
                }
            }
        }
    }
}

struct PrismBackground: View {
    var tint: Color = .purple
    var secondary: Color = .blue
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            Canvas { c, sz in
                c.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color(red: 0.04, green: 0.04, blue: 0.05)))

                // Spectral light dispersion caustics
                let center = CGPoint(x: sz.width * 0.5, y: sz.height * 0.5)
                let rays = 8
                for i in 0..<rays {
                    let a = t * 0.08 + Double(i) * (.pi * 2 / Double(rays))
                    let hue = Double(i) / Double(rays)
                    let col = Color(hue: hue, saturation: 0.8, brightness: 0.9).opacity(0.08)
                    let r: CGFloat = max(sz.width, sz.height) * 0.85
                    var p = Path()
                    p.move(to: center)
                    p.addLine(to: CGPoint(x: center.x + cos(a - 0.12) * r, y: center.y + sin(a - 0.12) * r))
                    p.addLine(to: CGPoint(x: center.x + cos(a + 0.12) * r, y: center.y + sin(a + 0.12) * r))
                    p.closeSubpath()
                    c.fill(p, with: .color(col))
                }
            }
        }
    }
}

struct AuroraBackground: View {
    var c0: Color
    var c1: Color
    var c2: Color
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            Canvas { c, sz in
                c.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color(red: 0.02, green: 0.03, blue: 0.06)))

                let auroraCols = [
                    Color(red: 0.1, green: 0.9, blue: 0.6), // Emerald
                    Color(red: 0.2, green: 0.6, blue: 1.0), // Cyan-Blue
                    Color(red: 0.7, green: 0.3, blue: 0.9)  // Violet
                ]

                for j in 0..<3 {
                    let jd = Double(j)
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: sz.height))
                    var x: CGFloat = 0
                    while x <= sz.width + 16 {
                        let ph = Double(x) / 180 + t * (0.35 + jd * 0.18) + jd * 1.5
                        let wave = sin(ph) * 0.45 + cos(ph * 0.6) * 0.35
                        let y = sz.height * (0.32 + CGFloat(jd) * 0.16) + CGFloat(wave) * 60
                        path.addLine(to: CGPoint(x: x, y: y))
                        x += 16
                    }
                    path.addLine(to: CGPoint(x: sz.width, y: sz.height))
                    path.closeSubpath()

                    let col = auroraCols[j % auroraCols.count]
                    c.fill(path, with: .linearGradient(
                        Gradient(colors: [col.opacity(0.22), col.opacity(0.04), .clear]),
                        startPoint: CGPoint(x: 0, y: sz.height * 0.25),
                        endPoint: CGPoint(x: 0, y: sz.height)
                    ))
                }
            }
        }
    }
}

struct MatrixBackground: View {
    var animated: Bool = true
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 25, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            Canvas { c, sz in
                c.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color(red: 0.01, green: 0.02, blue: 0.015)))
                let cols = 26
                let colW = sz.width / CGFloat(cols)
                let glyphs = ["ｦ", "ｱ", "ｳ", "ｴ", "ｵ", "ｶ", "ｷ", "ｹ", "ｺ", "ｻ", "ｼ", "ｽ", "ｾ", "ｿ", "ﾀ", "ﾂ", "ﾃ", "ﾅ", "ﾆ", "ﾇ", "ﾈ", "ﾊ", "ﾋ", "ﾎ", "ﾏ", "ﾐ", "ﾑ", "ﾒ", "ﾓ", "ﾔ", "ﾕ", "ﾗ", "ﾘ", "ﾜ", "0", "1", "2", "3", "7", "8", "9", "X", "Z"]
                for i in 0..<cols {
                    let speed = 65.0 + Double((i * 17) % 55)
                    let dropY = (t * speed + Double(i * 97)).truncatingRemainder(dividingBy: Double(sz.height + 200)) - 100
                    let x = CGFloat(i) * colW + colW * 0.5
                    for g in 0..<12 {
                        let gy = dropY - Double(g * 18)
                        if gy > 0 && gy < Double(sz.height) {
                            let charIdx = (i * 7 + g + Int(t * 3)) % glyphs.count
                            let char = glyphs[charIdx]
                            let op = max(0.05, 1.0 - Double(g) / 12.0)
                            let isHead = (g == 0)
                            let font = Font.system(size: 11, weight: isHead ? .bold : .regular, design: .monospaced)
                            let col = isHead ? Color.white : Color(red: 0.0, green: 0.95, blue: 0.35).opacity(op * 0.8)
                            c.draw(Text(char).font(font).foregroundStyle(col), at: CGPoint(x: x, y: gy))
                        }
                    }
                }
            }
        }
    }
}

struct RadarBackground: View {
    var animated: Bool = true
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            Canvas { c, sz in
                c.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color(red: 0.02, green: 0.04, blue: 0.03)))
                let center = CGPoint(x: sz.width / 2, y: sz.height / 2)
                let maxR = min(sz.width, sz.height) * 0.46
                let green = Color(red: 0.1, green: 0.9, blue: 0.4)

                // Concentric range rings
                for i in 1...4 {
                    let r = maxR * CGFloat(i) / 4.0
                    c.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                             with: .color(green.opacity(0.15)), lineWidth: 1)
                }

                // Crosshairs
                var cross = Path()
                cross.move(to: CGPoint(x: center.x - maxR, y: center.y))
                cross.addLine(to: CGPoint(x: center.x + maxR, y: center.y))
                cross.move(to: CGPoint(x: center.x, y: center.y - maxR))
                cross.addLine(to: CGPoint(x: center.x, y: center.y + maxR))
                c.stroke(cross, with: .color(green.opacity(0.18)), lineWidth: 0.8)

                // Rotating sweep beam
                let sweepA = (t * 1.6).truncatingRemainder(dividingBy: .pi * 2)
                var sweepPath = Path()
                sweepPath.move(to: center)
                sweepPath.addLine(to: CGPoint(x: center.x + cos(sweepA) * maxR, y: center.y + sin(sweepA) * maxR))
                c.stroke(sweepPath, with: .color(green.opacity(0.85)), lineWidth: 2)

                // Sweeping phosphor cone
                var cone = Path()
                cone.move(to: center)
                cone.addArc(center: center, radius: maxR, startAngle: .radians(sweepA - 0.5), endAngle: .radians(sweepA), clockwise: false)
                cone.closeSubpath()
                c.fill(cone, with: .radialGradient(
                    Gradient(colors: [green.opacity(0.2), .clear]),
                    center: center, startRadius: 0, endRadius: maxR
                ))
            }
        }
    }
}

struct SpotlightBackground: View {
    var tint: Color = .purple
    var animated: Bool = true
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            Canvas { c, sz in
                c.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color(red: 0.03, green: 0.03, blue: 0.04)))
                let sway = sin(t * 0.4) * sz.width * 0.12
                let topOrigin = CGPoint(x: sz.width * 0.5, y: -20)
                let bottomCenter = CGPoint(x: sz.width * 0.5 + sway, y: sz.height * 0.82)
                let bottomW: CGFloat = sz.width * 0.48

                // Volumetric light cone
                var cone = Path()
                cone.move(to: topOrigin)
                cone.addLine(to: CGPoint(x: bottomCenter.x - bottomW * 0.5, y: bottomCenter.y))
                cone.addLine(to: CGPoint(x: bottomCenter.x + bottomW * 0.5, y: bottomCenter.y))
                cone.closeSubpath()

                c.fill(cone, with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.16), tint.opacity(0.12), .clear]),
                    startPoint: topOrigin, endPoint: bottomCenter
                ))

                // Floor light oval
                let floorR = CGRect(x: bottomCenter.x - bottomW * 0.5, y: bottomCenter.y - 25, width: bottomW, height: 50)
                c.fill(Path(ellipseIn: floorR), with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.25), tint.opacity(0.15), .clear]),
                    center: bottomCenter, startRadius: 0, endRadius: bottomW * 0.5
                ))
            }
        }
    }
}

struct DiscBackground: View {
    var animated: Bool = true
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            Canvas { c, sz in
                c.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color(red: 0.04, green: 0.04, blue: 0.05)))
                let center = CGPoint(x: sz.width / 2, y: sz.height / 2)
                let maxR = min(sz.width, sz.height) * 0.45

                // Radial rainbow prismatic dispersion
                let rays = 12
                for i in 0..<rays {
                    let a = t * 0.25 + Double(i) * (.pi * 2 / Double(rays))
                    let hue = (Double(i) / Double(rays) + t * 0.05).truncatingRemainder(dividingBy: 1.0)
                    let col = Color(hue: hue, saturation: 0.75, brightness: 0.9).opacity(0.10)
                    var wedge = Path()
                    wedge.move(to: center)
                    wedge.addLine(to: CGPoint(x: center.x + cos(a) * maxR, y: center.y + sin(a) * maxR))
                    wedge.addLine(to: CGPoint(x: center.x + cos(a + 0.2) * maxR, y: center.y + sin(a + 0.2) * maxR))
                    wedge.closeSubpath()
                    c.fill(wedge, with: .color(col))
                }

                // Center hub
                c.stroke(Path(ellipseIn: CGRect(x: center.x - maxR, y: center.y - maxR, width: maxR * 2, height: maxR * 2)),
                         with: .color(Color.white.opacity(0.15)), lineWidth: 1)
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
        case .cyberpunk: CyberpunkBackground(animated: animated)
        case .quantum: QuantumBackground(tint: c0, secondary: c1, animated: animated)
        case .whisper:
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.06)
                RadialGradient(colors: [c0.opacity(0.12), .clear], center: .center, startRadius: 0, endRadius: 500)
            }
        case .zen:
            ZStack {
                Color(red: 0.06, green: 0.065, blue: 0.075)
                LinearGradient(colors: [Color.white.opacity(0.02), Color.clear], startPoint: .top, endPoint: .bottom)
            }
        case .prism: PrismBackground(tint: c0, secondary: c1, animated: animated)
        case .aurora: AuroraBackground(c0: c0, c1: c1, c2: c2, animated: animated)
        case .cassette:
            LinearGradient(colors: [Color(red: 0.08, green: 0.07, blue: 0.06), Color(red: 0.03, green: 0.03, blue: 0.03)], startPoint: .top, endPoint: .bottom)
        case .spotlight:
            SpotlightBackground(tint: c0, animated: animated)
        case .magazine:
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.065)
                LinearGradient(colors: [Color.white.opacity(0.04), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        case .ipod:
            LinearGradient(colors: [Color(white: 0.16), Color(white: 0.08)], startPoint: .top, endPoint: .bottom)
        case .matrix:
            MatrixBackground(animated: animated)
        case .radar:
            RadarBackground(animated: animated)
        case .disc:
            DiscBackground(animated: animated)
        case .cotodamaCanvas:
            CotodamaCanvasBackground(tint: c0, animated: animated)
        case .cotodamaFlow:
            CotodamaFlowBackground(c0: c0, c1: c1, animated: animated)
        case .cotodamaBeat:
            CotodamaBeatBackground(tint: c0, animated: animated)
        case .cotodamaBox:
            CotodamaBoxBackground(tint: c0, animated: animated)
        case .aura where !animated:
            ZStack {
                Color.black
                Circle().fill(c0).frame(width: 200, height: 200).offset(x: -60)
                Circle().fill(c1).frame(width: 200, height: 200).offset(x: 60, y: 30)
            }.blur(radius: 30)
        case .aura:
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
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
            VStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                        .shadow(color: .red, radius: 4)
                    Text("LIVE ON AIR").font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.red)
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.black.opacity(0.6), in: Capsule())
                .overlay(Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1))

                Text(text(index - 1))
                    .font(s.f(18, .medium))
                    .foregroundStyle(s.accent.opacity(0.2))
                    .lineLimit(1)

                ZStack {
                    Text(cur)
                        .font(s.f(46, .heavy))
                        .foregroundStyle(s.accent)
                        .blur(radius: 20)
                    Text(cur)
                        .font(s.f(46, .heavy))
                        .foregroundStyle(s.accent)
                        .blur(radius: 8)
                    Text(cur)
                        .font(s.f(46, .heavy))
                        .foregroundStyle(Color.white)
                        .shadow(color: s.accent, radius: 2)
                }
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.35)
                .padding(.horizontal, 36)
                .id(index)
                .transition(.opacity)

                Text(text(index + 1))
                    .font(s.f(18, .medium))
                    .foregroundStyle(s.accent.opacity(0.2))
                    .lineLimit(1)
            }
            .padding(40)
            .animation(.easeInOut(duration: 0.25), value: index)

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
            VStack(alignment: .leading, spacing: 16) {
                ForEach(-2...2, id: \.self) { d in
                    let i = index + d
                    let isCur = d == 0
                    HStack(spacing: 12) {
                        Circle()
                            .fill(isCur ? s.accent : Color.clear)
                            .frame(width: 6, height: 6)
                        Text(text(i))
                            .font(s.f(isCur ? 30 : 20, isCur ? .bold : .medium))
                            .foregroundStyle(isCur ? Color.white : Color.white.opacity(max(0.12, 0.45 - Double(abs(d)) * 0.15)))
                            .blur(radius: isCur ? 0 : CGFloat(abs(d)) * 1.2)
                            .lineLimit(2)
                    }
                    .offset(x: isCur ? 10 : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 48)
            .animation(.spring(response: 0.38, dampingFraction: 0.78), value: index)

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
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
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
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
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
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
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
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
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

        case .cyberpunk:
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Text("[ SYS // 0\(max(index + 1, 1)) ]").font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.0, green: 0.95, blue: 1.0))
                    Rectangle().fill(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.4)).frame(height: 1)
                    Text("\(fmtTime(pos))").font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(red: 1.0, green: 0.0, blue: 0.4))
                }
                .frame(maxWidth: 520)

                Text(text(index - 1))
                    .font(verseFont(s.font, 16 * CGFloat(s.scale), .medium))
                    .foregroundStyle(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.35))
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Text("«")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(red: 1.0, green: 0.0, blue: 0.4))

                    ZStack {
                        Text(cur)
                            .font(s.f(44, .black))
                            .foregroundStyle(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.7))
                            .offset(x: -2, y: 1)
                            .blur(radius: 2)

                        Text(cur)
                            .font(s.f(44, .black))
                            .foregroundStyle(Color(red: 1.0, green: 0.0, blue: 0.4).opacity(0.7))
                            .offset(x: 2, y: -1)
                            .blur(radius: 2)

                        Text(cur)
                            .font(s.f(44, .black))
                            .foregroundStyle(Color.white)
                    }
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.35)

                    Text("»")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(red: 0.0, green: 0.95, blue: 1.0))
                }
                .id(index)
                .transition(.scale(scale: 0.92).combined(with: .opacity))

                GeometryReader { bg in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 3)
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 1.0, green: 0.0, blue: 0.4)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: bg.size.width * CGFloat(progress), height: 3)
                            .shadow(color: Color(red: 0.0, green: 0.95, blue: 1.0), radius: 6)
                    }
                }
                .frame(height: 3)
                .frame(maxWidth: 420)

                Text(text(index + 1))
                    .font(verseFont(s.font, 16 * CGFloat(s.scale), .medium))
                    .foregroundStyle(Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.35))
                    .lineLimit(1)
            }
            .padding(40)
            .animation(.easeInOut(duration: 0.25), value: index)

        case .quantum:
            VStack(spacing: 20) {
                HStack {
                    Text("ψ [QUANTUM STATE 0\(max(index + 1, 1))]")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(s.accent.opacity(0.7))
                    Spacer()
                    Text("ENERGY: \(String(format: "%.2f", 4.2 + sin(pos * 2) * 1.5)) eV")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.cyan.opacity(0.6))
                }
                .frame(maxWidth: 480)

                ZStack {
                    Circle()
                        .stroke(LinearGradient(colors: [s.accent.opacity(0.4), .clear, Color.cyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                        .frame(width: 380, height: 160)
                        .rotationEffect(.degrees(pos * 18))

                    Text(cur)
                        .font(s.f(44, .heavy))
                        .foregroundStyle(Color.white)
                        .shadow(color: s.accent.opacity(0.85), radius: 18)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.35)
                        .padding(.horizontal, 36)
                        .id(index)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }

                Text(text(index + 1))
                    .font(s.f(17, .medium))
                    .foregroundStyle(s.accent.opacity(0.3))
                    .lineLimit(1)
            }
            .padding(40)
            .animation(.easeInOut(duration: 0.3), value: index)

        case .whisper:
            VStack(spacing: 20) {
                ForEach(-2...2, id: \.self) { offset in
                    let i = index + offset
                    let isCurrent = offset == 0
                    let dist = abs(offset)
                    Text(text(i))
                        .font(s.f(isCurrent ? 36 : 22, isCurrent ? .semibold : .regular))
                        .foregroundStyle(isCurrent ? Color.white : Color.white.opacity(0.3 - Double(dist) * 0.1))
                        .blur(radius: isCurrent ? 0 : CGFloat(dist) * 3.5)
                        .scaleEffect(isCurrent ? 1.0 : (1.0 - CGFloat(dist) * 0.05))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            }
            .padding(40)
            .animation(.easeInOut(duration: 0.4), value: index)

        case .zen:
            HStack(spacing: 36) {
                VStack(spacing: 0) {
                    Circle().fill(s.accent.opacity(0.7)).frame(width: 6, height: 6)
                    Rectangle().fill(LinearGradient(colors: [s.accent.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 1.5, height: 180)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text(text(index - 1))
                        .font(s.f(16, .light))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .lineLimit(1)

                    Text(cur)
                        .font(s.f(38, .light))
                        .foregroundStyle(Color(white: 0.96))
                        .lineSpacing(6)
                        .minimumScaleFactor(0.4)
                        .id(index)
                        .transition(.opacity)

                    Text(text(index + 1))
                        .font(s.f(16, .light))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(50)
            .animation(.easeInOut(duration: 0.45), value: index)

        case .prism:
            let beatPulse = CGFloat(sin(pos * 4) * 0.5 + 0.5)
            let split: CGFloat = 3.0 + 2.5 * beatPulse
            VStack(spacing: 16) {
                Text(text(index - 1))
                    .font(s.f(17, .semibold))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .lineLimit(1)

                ZStack {
                    Text(cur)
                        .font(s.f(50, .heavy))
                        .foregroundStyle(Color.red)
                        .offset(x: -split, y: 0)
                        .blendMode(.screen)

                    Text(cur)
                        .font(s.f(50, .heavy))
                        .foregroundStyle(Color.cyan)
                        .offset(x: split, y: 0)
                        .blendMode(.screen)

                    Text(cur)
                        .font(s.f(50, .heavy))
                        .foregroundStyle(Color.white)
                }
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.35)
                .id(index)
                .transition(.scale(scale: 0.94).combined(with: .opacity))

                Text(text(index + 1))
                    .font(s.f(17, .semibold))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .lineLimit(1)
            }
            .padding(40)
            .animation(.easeInOut(duration: 0.25), value: index)

        case .aurora:
            VStack(spacing: 18) {
                Text(text(index - 1))
                    .font(s.f(17, .medium).italic())
                    .foregroundStyle(Color(red: 0.2, green: 0.9, blue: 0.7).opacity(0.3))
                    .lineLimit(1)

                Text(cur)
                    .font(s.f(46, .bold).italic())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 1.0, blue: 0.7), Color(red: 0.3, green: 0.7, blue: 1.0), Color(red: 0.8, green: 0.4, blue: 1.0)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(red: 0.2, green: 0.9, blue: 0.7).opacity(0.6), radius: 16)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.35)
                    .id(index)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))

                Text(text(index + 1))
                    .font(s.f(17, .medium).italic())
                    .foregroundStyle(Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.3))
                    .lineLimit(1)
            }
            .padding(40)
            .animation(.easeInOut(duration: 0.35), value: index)

        case .cassette:
            CassetteTapeView(title: cur, artist: text(index + 1), progress: progress, accent: s.accent, animated: animated)
                .id(index)
                .transition(.scale(scale: 0.95).combined(with: .opacity))

        case .spotlight:
            VStack(spacing: 16) {
                Text(text(index - 1))
                    .font(s.f(16, .medium))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .lineLimit(1)

                Text(cur)
                    .font(s.f(46, .bold))
                    .foregroundStyle(Color.white)
                    .shadow(color: s.accent.opacity(0.9), radius: 24)
                    .shadow(color: .white.opacity(0.8), radius: 6)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.35)
                    .id(index)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))

                Text(text(index + 1))
                    .font(s.f(16, .medium))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .lineLimit(1)
            }
            .padding(40)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: index)

        case .magazine:
            EditorialMagazineView(cur: cur, prev: text(index - 1), next: text(index + 1), lineNum: index + 1, total: lines.count, accent: s.accent, s: s)
                .id(index)
                .transition(.opacity)

        case .ipod:
            IPodClassicView(cur: cur, next: text(index + 1), pos: pos, dur: lineDur, progress: progress, s: s)
                .id(index)
                .transition(.opacity)

        case .matrix:
            VStack(spacing: 16) {
                Text(text(index - 1))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.0, green: 0.9, blue: 0.3).opacity(0.3))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(">").font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.0, green: 1.0, blue: 0.4))
                    Text(cur)
                        .font(.system(size: 38 * CGFloat(s.scale), weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.35), radius: 12)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.35)
                }
                .id(index)
                .transition(.opacity)

                Text(text(index + 1))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.0, green: 0.9, blue: 0.3).opacity(0.3))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(48)
            .animation(.easeInOut(duration: 0.25), value: index)

        case .radar:
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.1, green: 0.9, blue: 0.4))
                    Text("SONAR TRACKING // BEARING \(Int((pos * 45).truncatingRemainder(dividingBy: 360)))°")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.1, green: 0.9, blue: 0.4).opacity(0.75))
                }

                Text(cur)
                    .font(.system(size: 40 * CGFloat(s.scale), weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color(red: 0.1, green: 0.9, blue: 0.4).opacity(0.9), radius: 14)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.35)
                    .id(index)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))

                Text(text(index + 1))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.1, green: 0.9, blue: 0.4).opacity(0.35))
                    .lineLimit(1)
            }
            .padding(44)
            .animation(.easeInOut(duration: 0.3), value: index)

        case .disc:
            CompactDiscView(cur: cur, next: text(index + 1), index: index + 1, total: lines.count, progress: progress, accent: s.accent, animated: animated, s: s)
                .id(index)
                .transition(.scale(scale: 0.94).combined(with: .opacity))

        case .cotodamaCanvas:
            CotodamaCanvasView(cur: cur, next: text(index + 1), index: index, progress: progress, accent: s.accent, animated: animated, s: s)
                .id(index)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                    removal: .opacity.combined(with: .scale(scale: 1.02))
                ))

        case .cotodamaFlow:
            CotodamaFlowView(cur: cur, prev: text(index - 1), next: text(index + 1), index: index, progress: progress, accent: s.accent, animated: animated, s: s)
                .id(index)
                .transition(.opacity)

        case .cotodamaBeat:
            CotodamaBeatView(cur: cur, next: text(index + 1), index: index, progress: progress, accent: s.accent, animated: animated, s: s)
                .id(index)
                .transition(.scale(scale: 1.04).combined(with: .opacity))

        case .cotodamaBox:
            CotodamaBoxView(cur: cur, next: text(index + 1), index: index, progress: progress, accent: s.accent, animated: animated, s: s)
                .id(index)
                .transition(.opacity)
        }
    }
}

struct CassetteTapeView: View {
    let title: String
    let artist: String
    let progress: Double
    let accent: Color
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            let spin = t * 120.0

            VStack(spacing: 16) {
                // Cassette Body
                ZStack {
                    // Outer shell
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [Color(white: 0.15), Color(white: 0.08)], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1.5))
                        .frame(width: 440, height: 260)
                        .shadow(color: .black.opacity(0.6), radius: 24, y: 12)

                    // 4 Corner screws
                    ForEach([(-195, -105), (195, -105), (-195, 105), (195, 105)], id: \.0) { ox, oy in
                        Circle().fill(Color(white: 0.28)).frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 1))
                            .offset(x: CGFloat(ox), y: CGFloat(oy))
                    }

                    VStack(spacing: 10) {
                        // Mixtape Sticker Label
                        VStack(spacing: 4) {
                            HStack {
                                Text("SIDE A").font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundStyle(Color.black.opacity(0.6))
                                Spacer()
                                Text("C-90 HIGH BIAS").font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.black.opacity(0.5))
                            }
                            Text(title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(white: 0.1))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .frame(width: 380)
                        .background(Color(white: 0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        // Center Window with 2 sprockets
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.black.opacity(0.85))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                .frame(width: 340, height: 110)

                            // Magnetic tape fill (left spool shrinks, right spool grows)
                            HStack(spacing: 40) {
                                // Left Reel
                                ZStack {
                                    Circle().fill(Color(red: 0.35, green: 0.18, blue: 0.12))
                                        .frame(width: CGFloat(70 - 25 * progress), height: CGFloat(70 - 25 * progress))
                                    Circle().fill(Color.white).frame(width: 36, height: 36)
                                    ForEach(0..<6) { i in
                                        Rectangle().fill(Color.black).frame(width: 4, height: 10)
                                            .offset(y: -14)
                                            .rotationEffect(.degrees(Double(i) * 60))
                                    }
                                }
                                .rotationEffect(.degrees(spin))

                                // Tape window counter
                                VStack(spacing: 2) {
                                    Text("TAPE")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.4))
                                    Text(String(format: "%03d", Int(progress * 100)))
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(accent)
                                }
                                .frame(width: 50)

                                // Right Reel
                                ZStack {
                                    Circle().fill(Color(red: 0.35, green: 0.18, blue: 0.12))
                                        .frame(width: CGFloat(45 + 25 * progress), height: CGFloat(45 + 25 * progress))
                                    Circle().fill(Color.white).frame(width: 36, height: 36)
                                    ForEach(0..<6) { i in
                                        Rectangle().fill(Color.black).frame(width: 4, height: 10)
                                            .offset(y: -14)
                                            .rotationEffect(.degrees(Double(i) * 60))
                                    }
                                }
                                .rotationEffect(.degrees(spin))
                            }
                        }
                    }
                }

                // Subtitle / Next Line under cassette
                if !artist.isEmpty {
                    Text(artist)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .lineLimit(1)
                }
            }
        }
    }
}

struct EditorialMagazineView: View {
    let cur: String
    let prev: String
    let next: String
    let lineNum: Int
    let total: Int
    let accent: Color
    let s: LStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Magazine Header
            HStack {
                Text("THE LYRIC REVIEW").font(.system(size: 13, weight: .black, design: .serif)).tracking(3)
                Spacer()
                Text("VOL. \(max(1, lineNum)) // \(total)").font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(accent)
            }
            .padding(.bottom, 6)
            .overlay(Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1), alignment: .bottom)

            // Two-column editorial spread
            HStack(alignment: .top, spacing: 32) {
                // Left Column: Big active quote with Drop Cap
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 8) {
                        if let firstChar = cur.first {
                            Text(String(firstChar))
                                .font(.system(size: 64, weight: .bold, design: .serif))
                                .foregroundStyle(accent)
                                .lineLimit(1)
                            Text(String(cur.dropFirst()))
                                .font(s.f(36, .bold))
                                .foregroundStyle(Color.white)
                                .minimumScaleFactor(0.4)
                        } else {
                            Text(cur).font(s.f(36, .bold))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Vertical Column Divider
                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 160)

                // Right Column: Annotations and Next line
                VStack(alignment: .leading, spacing: 14) {
                    Text("COMING UP:").font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Text(next.isEmpty ? "—" : next)
                        .font(s.f(18, .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(3)

                    Spacer()

                    // Editorial barcode badge
                    HStack(spacing: 2) {
                        ForEach(0..<18) { k in
                            Rectangle().fill(Color.white.opacity(k % 3 == 0 ? 0.6 : 0.2))
                                .frame(width: CGFloat(k % 2 == 0 ? 3 : 1.5), height: 20)
                        }
                    }
                }
                .frame(width: 160, alignment: .leading)
            }
            .frame(maxWidth: 620)
        }
        .padding(44)
    }
}

struct IPodClassicView: View {
    let cur: String
    let next: String
    let pos: Double
    let dur: Double
    let progress: Double
    let s: LStyle

    var body: some View {
        VStack(spacing: 16) {
            // iPod 2-inch LCD Screen
            VStack(spacing: 0) {
                // Header Bar (Apple classic blue gradient)
                HStack {
                    Image(systemName: "play.fill").font(.system(size: 9))
                    Spacer()
                    Text("Now Playing").font(.system(size: 12, weight: .bold, design: .default))
                    Spacer()
                    Image(systemName: "battery.75").font(.system(size: 12))
                }
                .foregroundStyle(Color.black.opacity(0.85))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(LinearGradient(colors: [Color(red: 0.85, green: 0.90, blue: 0.98), Color(red: 0.65, green: 0.75, blue: 0.90)], startPoint: .top, endPoint: .bottom))
                .overlay(Rectangle().fill(Color.black.opacity(0.2)).frame(height: 1), alignment: .bottom)

                // Screen body
                VStack(spacing: 12) {
                    Spacer()
                    Text(cur)
                        .font(.system(size: 26 * CGFloat(s.scale), weight: .bold, design: .default))
                        .foregroundStyle(Color.black.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.4)
                        .padding(.horizontal, 20)
                    if !next.isEmpty {
                        Text(next)
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundStyle(Color.black.opacity(0.45))
                            .lineLimit(1)
                    }
                    Spacer()

                    // Diamond Scrubber Progress Bar
                    VStack(spacing: 4) {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.15))
                                RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.2, green: 0.5, blue: 0.9))
                                    .frame(width: g.size.width * CGFloat(progress))
                                // Diamond head
                                Image(systemName: "suit.diamond.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(red: 0.1, green: 0.4, blue: 0.85))
                                    .offset(x: max(0, g.size.width * CGFloat(progress) - 5))
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text(fmtTime(pos))
                            Spacer()
                            Text("-\(fmtTime(max(0, dur - pos)))")
                        }
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.black.opacity(0.6))
                    }
                    .padding(.horizontal, 16).padding(.bottom, 12)
                }
                .background(Color(red: 0.92, green: 0.95, blue: 0.98))
            }
            .frame(width: 360, height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.3), lineWidth: 2))
            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)

            // Click Wheel hint
            ZStack {
                Circle().fill(Color(white: 0.22)).frame(width: 110, height: 110)
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                Circle().fill(Color(white: 0.3)).frame(width: 44, height: 44)
                Text("MENU").font(.system(size: 8, weight: .bold, design: .default)).foregroundStyle(Color.white.opacity(0.6)).offset(y: -36)
                Image(systemName: "forward.end.alt.fill").font(.system(size: 8)).foregroundStyle(Color.white.opacity(0.6)).offset(x: 36)
                Image(systemName: "backward.end.alt.fill").font(.system(size: 8)).foregroundStyle(Color.white.opacity(0.6)).offset(x: -36)
                Image(systemName: "playpause.fill").font(.system(size: 8)).foregroundStyle(Color.white.opacity(0.6)).offset(y: 36)
            }
        }
    }
}

struct CompactDiscView: View {
    @ObservedObject var np = NowPlaying.shared
    let cur: String
    let next: String
    let index: Int
    let total: Int
    let progress: Double
    let accent: Color
    var animated: Bool = true
    let s: LStyle

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !np.isPlaying)) { ctx in
            let spin = animated && np.isPlaying ? np.position(at: ctx.date) * 80.0 : 0.0

            HStack(spacing: 36) {
                // CD Disc with Album Art Picture Disc
                ZStack {
                    // Outer mirror aluminum bevel
                    Circle()
                        .fill(RadialGradient(colors: [Color(white: 0.94), Color(white: 0.74), Color(white: 0.88)], center: .center, startRadius: 90, endRadius: 105))
                        .frame(width: 210, height: 210)
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.2))
                        .shadow(color: .black.opacity(0.45), radius: 20, y: 10)

                    // Album Artwork Face (Picture Disc)
                    Group {
                        if let art = np.artwork {
                            Image(nsImage: art)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 196, height: 196)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(LinearGradient(colors: [accent, np.colors.count > 1 ? np.colors[1] : .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 196, height: 196)
                        }
                    }

                    // Iridescent Spectral Hologram Reflection Overlay (Rainbow diffraction)
                    Circle()
                        .fill(AngularGradient(colors: [
                            .clear,
                            Color(red: 1.0, green: 0.2, blue: 0.4).opacity(0.24),
                            Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.28),
                            Color(red: 0.2, green: 0.9, blue: 0.6).opacity(0.25),
                            Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.28),
                            Color(red: 0.8, green: 0.3, blue: 0.9).opacity(0.24),
                            .clear,
                            Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.22),
                            Color(red: 0.3, green: 0.8, blue: 0.9).opacity(0.25),
                            .clear
                        ], center: .center))
                        .frame(width: 196, height: 196)
                        .blendMode(.screen)

                    // Dual Shimmer Highlights (optical light reflections)
                    Circle()
                        .fill(AngularGradient(colors: [
                            .clear,
                            Color.white.opacity(0.35),
                            .clear,
                            Color.white.opacity(0.35),
                            .clear
                        ], center: .center))
                        .frame(width: 196, height: 196)
                        .blendMode(.overlay)

                    // Concentric Micro-Track Grooves
                    ForEach([180, 150, 120, 95], id: \.self) { r in
                        Circle()
                            .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                            .frame(width: CGFloat(r), height: CGFloat(r))
                    }

                    // Inner Clear Stacking Ring / Mirror Hub (standard transparent plastic ring)
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.black.opacity(0.45), Color.white.opacity(0.18), Color.black.opacity(0.35)],
                            center: .center, startRadius: 15, endRadius: 36
                        ))
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))

                    // Inner Clear Mirror Band
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.8))

                    // Center Spindle Hole (standard 15mm CD center hole)
                    Circle()
                        .fill(Color(white: 0.08))
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.white.opacity(0.65), lineWidth: 1.2))
                }
                .rotationEffect(.degrees(spin))

                // Track and Lyric Info
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Text("COMPACT DISC DIGITAL AUDIO")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.4))
                        Spacer()
                        Text("TRK \(index)/\(total)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(accent)
                    }

                    Text(cur)
                        .font(s.f(38, .heavy))
                        .foregroundStyle(Color.white)
                        .shadow(color: accent.opacity(0.7), radius: 10)
                        .minimumScaleFactor(0.4)

                    if !next.isEmpty {
                        Text(next)
                            .font(s.f(16, .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(40)
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
        TimelineView(.animation(minimumInterval: PowerOptimizer.shared.animationInterval, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
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
                let realPos = animated ? (NowPlaying.shared.position(at: ctx.date) + LyricsStore.shared.totalOffset + 0.25) : pos
                let elapsed = max(0, realPos - curLine.time)
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

// MARK: - COTODAMA Lyric Speaker Themes

// 1. COTODAMA CANVAS
struct CotodamaCanvasBackground: View {
    var tint: Color = .white
    var animated: Bool = true

    var body: some View {
        ZStack {
            // Fine Gallery Matte Slate Canvas Base
            Color(red: 0.08, green: 0.082, blue: 0.09)

            // Subtle Architectural Grid & Registration Hairlines
            Canvas { c, size in
                let w = size.width, h = size.height
                var gridPath = Path()
                for y in stride(from: 40.0, to: h - 30.0, by: 40.0) {
                    gridPath.move(to: CGPoint(x: 30, y: y))
                    gridPath.addLine(to: CGPoint(x: w - 30, y: y))
                }
                for x in stride(from: 40.0, to: w - 30.0, by: 60.0) {
                    gridPath.move(to: CGPoint(x: x, y: 30))
                    gridPath.addLine(to: CGPoint(x: x, y: h - 30))
                }
                c.stroke(gridPath, with: .color(Color.white.opacity(0.025)), lineWidth: 0.5)

                // Corner Registration Marks (+)
                let corners: [CGPoint] = [
                    CGPoint(x: 28, y: 28),
                    CGPoint(x: w - 28, y: 28),
                    CGPoint(x: 28, y: h - 28),
                    CGPoint(x: w - 28, y: h - 28)
                ]
                for pt in corners {
                    var cross = Path()
                    cross.move(to: CGPoint(x: pt.x - 7, y: pt.y))
                    cross.addLine(to: CGPoint(x: pt.x + 7, y: pt.y))
                    cross.move(to: CGPoint(x: pt.x, y: pt.y - 7))
                    cross.addLine(to: CGPoint(x: pt.x, y: pt.y + 7))
                    c.stroke(cross, with: .color(Color.white.opacity(0.28)), lineWidth: 1.0)
                }
            }

            // Ambient Subtle Light Wash
            RadialGradient(
                colors: [tint.opacity(0.08), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )

            // Technical Headers & Labels
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("COTODAMA // LYRIC SYNC TECHNOLOGY")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.5))
                        Text("AIST JAPAN COOP // MOTION GRAPHIC ENGINE")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.28))
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(NowPlaying.shared.isPlaying ? Color.green : Color.orange)
                            .frame(width: 5, height: 5)
                        Text("CANVAS DUAL-BOARD")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.05), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6))
                }
                .padding(.horizontal, 36)
                .padding(.top, 24)

                Spacer()

                // Bottom Footer Spec
                HStack {
                    Text("MODEL: LSC-01 // JAPAN DESIGN // ACOUSTIC CANV-02")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                    Spacer()
                    Text("GRAPHIC IMPRESSION MAPPING")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.25))
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 22)
            }
        }
    }
}

struct CotodamaCanvasView: View {
    let cur: String
    let next: String
    let index: Int
    let progress: Double
    let accent: Color
    var animated: Bool = true
    let s: LStyle

    var body: some View {
        let words = cur.split(separator: " ").map(String.init)
        let activeIdx = words.isEmpty ? 0 : min(words.count - 1, Int(progress * Double(words.count)))

        VStack(spacing: 24) {
            Spacer()

            if words.isEmpty {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Rectangle().fill(accent).frame(width: 14, height: 2)
                        Text("COTODAMA LYRIC SPEAKER")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                        Rectangle().fill(accent).frame(width: 14, height: 2)
                    }
                    Text("♪")
                        .font(.system(size: 38, weight: .thin))
                        .foregroundStyle(.white.opacity(0.3))
                }
            } else {
                // Cotodama Dynamic Kinetic Typography Grid
                VStack(alignment: s.align == .leading ? .leading : .center, spacing: 14) {
                    let mid = max(1, (words.count + 1) / 2)
                    let row1 = Array(words.prefix(mid))
                    let row2 = Array(words.dropFirst(mid))

                    // Row 1
                    HStack(spacing: 12) {
                        ForEach(Array(row1.enumerated()), id: \.offset) { i, w in
                            let isCur = i == activeIdx
                            let isPast = i < activeIdx
                            Text(s.upper ? w.uppercased() : w)
                                .font(s.f(isCur ? 56 : (row2.isEmpty ? 50 : 38), isCur ? .black : (isPast ? .bold : .medium)))
                                .foregroundStyle(isCur ? Color.white : (isPast ? Color.white.opacity(0.85) : Color.white.opacity(0.28)))
                                .scaleEffect(isCur ? 1.05 : 1.0)
                                .overlay(alignment: .bottom) {
                                    if isCur {
                                        Rectangle()
                                            .fill(accent)
                                            .frame(height: 3)
                                            .offset(y: 4)
                                    }
                                }
                                .animation(.spring(response: 0.25, dampingFraction: 0.72), value: activeIdx)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: s.align == .leading ? .leading : .center)

                    // Row 2 (if words > 1)
                    if !row2.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(Array(row2.enumerated()), id: \.offset) { j, w in
                                let i = mid + j
                                let isCur = i == activeIdx
                                let isPast = i < activeIdx
                                Text(s.upper ? w.uppercased() : w)
                                    .font(s.f(isCur ? 56 : 38, isCur ? .black : (isPast ? .bold : .medium)))
                                    .foregroundStyle(isCur ? Color.white : (isPast ? Color.white.opacity(0.85) : Color.white.opacity(0.28)))
                                    .scaleEffect(isCur ? 1.05 : 1.0)
                                    .overlay(alignment: .bottom) {
                                        if isCur {
                                            Rectangle()
                                                .fill(accent)
                                                .frame(height: 3)
                                                .offset(y: 4)
                                        }
                                    }
                                    .animation(.spring(response: 0.25, dampingFraction: 0.72), value: activeIdx)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: s.align == .leading ? .leading : .center)
                    }
                }
                .padding(.horizontal, 48)
            }

            Spacer()

            // Next Line Monospace Teaser
            if !next.isEmpty {
                HStack(spacing: 6) {
                    Text("NEXT //")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent.opacity(0.7))
                    Text(next)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.04), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.7))
                .padding(.bottom, 24)
            }
        }
    }
}

// 2. COTODAMA FLOW (Poetic Ballad & Acoustic Motion)
struct CotodamaFlowBackground: View {
    var c0: Color
    var c1: Color
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            ZStack {
                // Smoked Glass Base
                LinearGradient(
                    colors: [
                        Color(red: 0.035, green: 0.038, blue: 0.06),
                        Color(red: 0.015, green: 0.018, blue: 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Ethereal Floating Liquid Light Orbs
                let ox1 = sin(t * 0.4) * 160
                let oy1 = cos(t * 0.35) * 90
                Circle()
                    .fill(c0.opacity(0.22))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: CGFloat(ox1), y: CGFloat(oy1))

                let ox2 = cos(t * 0.38) * 150
                let oy2 = sin(t * 0.45) * 80
                Circle()
                    .fill(c1.opacity(0.18))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: CGFloat(ox2), y: CGFloat(oy2))
            }
        }
    }
}

struct CotodamaFlowView: View {
    let cur: String
    let prev: String
    let next: String
    let index: Int
    let progress: Double
    let accent: Color
    var animated: Bool = true
    let s: LStyle

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0

            VStack(spacing: 24) {
                Spacer()

                // Previous Line Dissolving Upwards
                if !prev.isEmpty {
                    Text(prev)
                        .font(.system(size: 20 * CGFloat(s.scale), weight: .light, design: .serif))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .multilineTextAlignment(.center)
                        .blur(radius: 1.2)
                        .offset(y: -8)
                        .lineLimit(1)
                }

                // Active Hero Lyric Line: Liquid Floating Typography with Ethereal Aura
                ZStack {
                    // Ethereal Blurred Aura
                    Text(s.upper ? cur.uppercased() : cur)
                        .font(.system(size: 44 * CGFloat(s.scale), weight: .regular, design: .serif))
                        .foregroundStyle(accent.opacity(0.55))
                        .blur(radius: 16)
                        .offset(y: CGFloat(sin(t * 1.6) * 3))

                    // Synchronized Filling Text
                    FillText(
                        text: s.upper ? cur.uppercased() : cur,
                        p: progress,
                        on: Color.white,
                        off: Color.white.opacity(0.38)
                    )
                    .font(.system(size: 44 * CGFloat(s.scale), weight: .regular, design: .serif))
                    .shadow(color: Color.black.opacity(0.4), radius: 6, y: 3)
                    .offset(y: CGFloat(sin(t * 1.6) * 3))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

                // Upcoming Line Floating Below
                if !next.isEmpty {
                    Text(next)
                        .font(.system(size: 20 * CGFloat(s.scale), weight: .light, design: .serif))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .multilineTextAlignment(.center)
                        .blur(radius: 1.2)
                        .offset(y: 8)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
    }
}

// 3. COTODAMA KINETIC (High-Energy Rock / Pop / Strobe)
struct CotodamaBeatBackground: View {
    var tint: Color = .white
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            let beatPulse = abs(sin(t * 3.5))

            ZStack {
                // Stark Obsidian Canvas
                Color(red: 0.02, green: 0.02, blue: 0.025)

                // Flashing Minimalist Hairline Cross
                Canvas { c, size in
                    let w = size.width, h = size.height
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w, y: h * 0.5))
                    p.move(to: CGPoint(x: w * 0.5, y: 0))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h))
                    c.stroke(p, with: .color(Color.white.opacity(0.04 + 0.04 * beatPulse)), lineWidth: 0.8)
                }

                // Geometric Corner Framing Brackets
                VStack {
                    HStack {
                        Text("[ 01 // KINETIC STROBE ]")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.45))
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { i in
                                Rectangle()
                                    .fill(tint.opacity(Double(i) * 0.25 + 0.25))
                                    .frame(width: 3, height: 10 + CGFloat(sin(t * 8 + Double(i)) * 6))
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                    Spacer()

                    HStack {
                        Text("TEMPO IMPRESSION SYNC")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                        Spacer()
                        Text("COTODAMA // TOKYO")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.25))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 22)
                }
            }
        }
    }
}

struct CotodamaBeatView: View {
    let cur: String
    let next: String
    let index: Int
    let progress: Double
    let accent: Color
    var animated: Bool = true
    let s: LStyle

    var body: some View {
        let words = cur.split(separator: " ").map(String.init)
        let activeIdx = words.isEmpty ? 0 : min(words.count - 1, Int(progress * Double(words.count)))

        VStack(spacing: 28) {
            Spacer()

            if words.isEmpty {
                Text("♪")
                    .font(.system(size: 64, weight: .black))
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                // High-Contrast Inverted Block Typography Flow
                FlowLayout(spacing: 12) {
                    ForEach(Array(words.enumerated()), id: \.offset) { i, w in
                        let isCur = i == activeIdx
                        let isPast = i < activeIdx

                        Text(s.upper ? w.uppercased() : w)
                            .font(.system(size: (isCur ? 48 : 40) * CGFloat(s.scale), weight: .black, design: .default))
                            .foregroundStyle(isCur ? Color.black : (isPast ? Color.white : Color.white.opacity(0.3)))
                            .padding(.horizontal, isCur ? 14 : 0)
                            .padding(.vertical, isCur ? 6 : 0)
                            .background(
                                Group {
                                    if isCur {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.white)
                                            .shadow(color: Color.white.opacity(0.5), radius: 8)
                                    }
                                }
                            )
                            .animation(.spring(response: 0.18, dampingFraction: 0.65), value: activeIdx)
                    }
                }
                .padding(.horizontal, 44)
            }

            Spacer()

            if !next.isEmpty {
                Text(next.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .padding(.bottom, 28)
            }
        }
    }
}

// 4. COTODAMA BOX (Transparent Acrylic Cabinet & Acoustic Drivers)
struct CotodamaBoxBackground: View {
    var tint: Color = .white
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !animated || !NowPlaying.shared.isPlaying)) { ctx in
            let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
            let excursion = NowPlaying.shared.isPlaying ? CGFloat(sin(t * 10) * 3) : 0

            ZStack {
                // Smoked Acrylic Cabinet Base
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.055, blue: 0.07),
                        Color(red: 0.02, green: 0.022, blue: 0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Background Acoustic Drivers (Visible through transparent LCD)
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let centerX = w / 2
                    let centerY = h / 2

                    ZStack {
                        // 1. High-Frequency Tweeter (Top)
                        ZStack {
                            Circle().fill(Color(white: 0.12)).frame(width: 80, height: 80)
                            Circle().stroke(Color.white.opacity(0.15), lineWidth: 2).frame(width: 80, height: 80)
                            Circle().fill(RadialGradient(colors: [Color(white: 0.3), Color(white: 0.08)], center: .center, startRadius: 0, endRadius: 28)).frame(width: 56, height: 56)
                            Circle().fill(Color.white.opacity(0.25)).frame(width: 14, height: 14)
                        }
                        .position(x: centerX, y: centerY - 110)

                        // 2. Bass Woofer Driver with Voice Coil Ridges (Bottom)
                        ZStack {
                            // Driver basket outer ring
                            Circle().fill(Color(white: 0.09)).frame(width: 190, height: 190)
                            Circle().stroke(Color.white.opacity(0.12), lineWidth: 2.5).frame(width: 190, height: 190)

                            // Concentric voice coil ridges
                            ForEach(0..<4, id: \.self) { i in
                                Circle()
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1.5)
                                    .frame(width: 160 - CGFloat(i * 26) + excursion,
                                           height: 160 - CGFloat(i * 26) + excursion)
                            }

                            // Center dust cap (pulses with excursion)
                            Circle()
                                .fill(RadialGradient(colors: [Color(white: 0.22), Color(white: 0.06)], center: .center, startRadius: 0, endRadius: 32))
                                .frame(width: 58 + excursion * 1.5, height: 58 + excursion * 1.5)
                                .shadow(color: Color.black.opacity(0.6), radius: 6)
                        }
                        .position(x: centerX, y: centerY + 80)
                    }
                }

                // Fine Transparent LCD Dot-Matrix Overlay
                Canvas { c, size in
                    let step: CGFloat = 8.0
                    for y in stride(from: 4.0, to: size.height, by: step) {
                        for x in stride(from: 4.0, to: size.width, by: step) {
                            c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)),
                                   with: .color(Color.white.opacity(0.04)))
                        }
                    }
                }

                // Top & Bottom Cabinet Acrylic Rim
                VStack {
                    HStack {
                        Text("COTODAMA // LYRIC SPEAKER BOX")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.55))
                        Spacer()
                        Text("TRANSPARENT LCD // DUAL ACOUSTIC")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 24)

                    Spacer()

                    // Bottom Equalizer Strip
                    HStack(spacing: 3) {
                        ForEach(0..<16, id: \.self) { i in
                            let h = NowPlaying.shared.isPlaying ? max(4, CGFloat(abs(sin(t * 4 + Double(i) * 0.4)) * 14)) : 4
                            Capsule()
                                .fill(LinearGradient(colors: [tint, tint.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 2.5, height: h)
                        }
                    }
                    .padding(.bottom, 22)
                }
            }
        }
    }
}

struct CotodamaBoxView: View {
    let cur: String
    let next: String
    let index: Int
    let progress: Double
    let accent: Color
    var animated: Bool = true
    let s: LStyle

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Suspended LCD Floating Typography
            ZStack {
                // Subtle LCD Ghost Reflection
                Text(s.upper ? cur.uppercased() : cur)
                    .font(.system(size: 40 * CGFloat(s.scale), weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.18))
                    .offset(x: 2, y: 3)

                // Sharp Foreground Floating Text
                FillText(
                    text: s.upper ? cur.uppercased() : cur,
                    p: progress,
                    on: Color.white,
                    off: Color.white.opacity(0.4)
                )
                .font(.system(size: 40 * CGFloat(s.scale), weight: .heavy, design: .rounded))
                .shadow(color: Color.black.opacity(0.65), radius: 8, y: 4)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 48)

            Spacer()

            if !next.isEmpty {
                Text(next)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.28))
                    .lineLimit(1)
                    .padding(.bottom, 32)
            }
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
        guard np.isPlaying else { return 1.0 }
        let smooth: [LyricTheme] = [.karaoke, .poster, .typewriter, .metric, .pop, .glitch, .cinema, .stars, .cyberpunk, .quantum, .prism, .aurora, .cassette, .spotlight, .magazine, .ipod, .matrix, .radar, .disc, .cotodamaCanvas, .cotodamaFlow, .cotodamaBeat, .cotodamaBox]
        let interval = PowerOptimizer.shared.isLowPowerMode ? 0.033 : 0.016
        return smooth.contains(theme) ? interval : 0.1
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
