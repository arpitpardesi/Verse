import SwiftUI

/// A vinyl record that spins with the playback position (freezes on pause, follows seeks).
struct RecordView: View {
    @ObservedObject var np = NowPlaying.shared
    var size: CGFloat
    var animated = true
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animated || !np.isPlaying)) { ctx in
            let angle = np.position(at: ctx.date) * 100
            ZStack {
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(white: 0.16), .black], center: .center, startRadius: 0, endRadius: size / 2))
                    ForEach(0..<7, id: \.self) { i in
                        Circle().stroke(Color.white.opacity(0.06), lineWidth: 1).padding(size * (0.04 + 0.05 * CGFloat(i)))
                    }
                    if let a = np.artwork {
                        Image(nsImage: a).resizable().scaledToFill().frame(width: size * 0.38, height: size * 0.38).clipShape(Circle())
                    } else {
                        Circle().fill(np.colors.first ?? .pink).frame(width: size * 0.38, height: size * 0.38)
                    }
                    Circle().fill(Color.black).frame(width: size * 0.04, height: size * 0.04)
                }
                .rotationEffect(.degrees(angle))
                Circle().fill(AngularGradient(colors: [.clear, .white.opacity(0.14), .clear, .white.opacity(0.14), .clear], center: .center))
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size, height: size)
    }
}

struct RecordWidget: View {
    @ObservedObject var np = NowPlaying.shared
    @AppStorage(K.recordStyle) private var style = "turntable"
    var tint: Color { np.colors.first ?? .pink }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                switch style {
                case "sleeve":
                    ZStack {
                        RecordView(size: 210).offset(x: np.isPlaying ? 70 : 28)
                        CoverView(art: np.artwork, size: 220, radius: 10).shadow(radius: 14)
                    }
                    .animation(.spring(duration: 0.8), value: np.isPlaying)
                case "aura":
                    ZStack {
                        Circle().fill(tint).frame(width: 220, height: 220).blur(radius: 60).opacity(0.8)
                        CoverView(art: np.artwork, size: 220, radius: 22).shadow(radius: 20)
                    }
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.black.opacity(0.55))
                            .frame(width: 280, height: 260)
                        RecordView(size: 220)
                        Capsule().fill(Color(white: 0.85)).frame(width: 5, height: 130)
                            .rotationEffect(.degrees(np.isPlaying ? 24 : 4), anchor: .top)
                            .offset(x: 105, y: -62)
                            .animation(.easeInOut(duration: 0.8), value: np.isPlaying)
                    }
                }
            }
            .frame(width: 300, height: 270)
            VStack(spacing: 2) {
                Text(np.track?.title ?? "Nothing playing").font(.system(size: 15, weight: .semibold)).lineLimit(1)
                Text(np.track?.artist ?? "").font(.system(size: 12)).opacity(0.7).lineLimit(1)
            }
            .foregroundStyle(.white).shadow(color: .black.opacity(0.6), radius: 4)
        }
        .padding(10)
    }
}
