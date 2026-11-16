import SwiftUI
import AppKit

enum ArtEffect: String, CaseIterable, Identifiable {
    case aura, blur, full, kenburns, duotone, split
    var id: String { rawValue }
    var title: String {
        switch self {
        case .aura: return "Aura"
        case .blur: return "Soft blur"
        case .full: return "Full art"
        case .kenburns: return "Ken Burns"
        case .duotone: return "Duotone"
        case .split: return "Split"
        }
    }
}

/// Used for previews when nothing is playing.
func placeholderArt(_ colors: [Color]) -> NSImage {
    let img = NSImage(size: NSSize(width: 300, height: 300))
    img.lockFocus()
    let c = colors.isEmpty ? [Color.purple, .blue, .pink] : colors
    NSGradient(colors: [NSColor(c[0]), NSColor(c[1 % c.count]), NSColor(c[2 % c.count])])?
        .draw(in: NSRect(x: 0, y: 0, width: 300, height: 300), angle: 45)
    img.unlockFocus()
    return img
}

/// Album art as a background layer, with selectable looks. Draw it over any theme background.
struct ArtBackground: View {
    let art: NSImage?
    let colors: [Color]
    let effect: String
    let dim: Double
    var animated = true

    var body: some View {
        GeometryReader { g in
            if let art { layer(art, g.size) }
        }
        .clipped()
        .allowsHitTesting(false)
    }

    func fill(_ art: NSImage, _ size: CGSize) -> some View {
        Image(nsImage: art).resizable().scaledToFill()
            .frame(width: size.width, height: size.height).clipped()
    }

    @ViewBuilder func layer(_ art: NSImage, _ size: CGSize) -> some View {
        let accent = colors.first ?? .pink
        switch effect {
        case "blur":
            ZStack {
                fill(art, size).blur(radius: 60).saturation(1.3)
                Color.black.opacity(dim)
            }
        case "full":
            ZStack {
                fill(art, size)
                LinearGradient(colors: [Color.black.opacity(dim * 0.6), Color.black.opacity(min(1, dim * 1.4))],
                               startPoint: .top, endPoint: .bottom)
            }
        case "duotone":
            ZStack {
                fill(art, size).saturation(0).contrast(1.15).colorMultiply(accent)
                Color.black.opacity(dim)
            }
        case "split":
            ZStack(alignment: .leading) {
                fill(art, CGSize(width: size.width * 0.6, height: size.height))
                    .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(width: size.width, alignment: .leading)
                Color.black.opacity(dim * 0.5)
            }
        case "kenburns":
            TimelineView(.animation(minimumInterval: 1.0 / 15, paused: !animated)) { ctx in
                let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
                ZStack {
                    fill(art, size).blur(radius: 3)
                        .scaleEffect(1.18 + 0.1 * CGFloat(sin(t / 9)))
                        .offset(x: CGFloat(sin(t / 13)) * size.width * 0.04, y: CGFloat(cos(t / 11)) * size.height * 0.04)
                    Color.black.opacity(dim)
                }
            }
        default: // aura
            TimelineView(.animation(minimumInterval: 1.0 / 15, paused: !animated)) { ctx in
                let t = animated ? ctx.date.timeIntervalSinceReferenceDate : 0
                ZStack {
                    fill(art, size).blur(radius: 70).saturation(1.5).drawingGroup()
                        .scaleEffect(1.5)
                        .rotationEffect(.degrees(t * 3))
                    RadialGradient(colors: [accent.opacity(0.35), .clear], center: .center,
                                   startRadius: 0, endRadius: size.width * 0.6)
                        .offset(x: CGFloat(sin(t / 5)) * size.width * 0.15, y: CGFloat(cos(t / 7)) * size.height * 0.15)
                    Color.black.opacity(dim * 0.7)
                }
            }
        }
    }
}
