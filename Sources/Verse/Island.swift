import SwiftUI

struct EqualizerBars: View {
    @ObservedObject var np = NowPlaying.shared
    var tint: Color
    var height: CGFloat = 22
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<4, id: \.self) { i in
                    let h = np.isPlaying ? 0.25 + 0.75 * abs(sin(t * (2.2 + Double(i) * 0.9) + Double(i))) : 0.2
                    Capsule().fill(tint).frame(width: 3, height: height * CGFloat(h))
                }
            }
            .frame(height: height)
        }
    }
}

struct SeekBar: View {
    @ObservedObject var np = NowPlaying.shared
    var tint: Color
    @State private var dragging: Double? = nil

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { ctx in
            let dur = max(np.track?.duration ?? 1, 1)
            let pos = dragging ?? min(np.position(at: ctx.date), dur)
            VStack(spacing: 2) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.2))
                        Capsule().fill(tint).frame(width: max(0, geo.size.width * pos / dur))
                    }
                    .frame(height: 5).offset(y: 5)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { dragging = min(max($0.location.x / geo.size.width, 0), 1) * dur }
                        .onEnded { v in
                            np.seek(to: min(max(v.location.x / geo.size.width, 0), 1) * dur)
                            dragging = nil
                        })
                }
                .frame(height: 16)
                HStack {
                    Text(fmtTime(pos)); Spacer(); Text(fmtTime(dur))
                }
                .font(.system(size: 10).monospacedDigit()).foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

struct IslandView: View {
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared
    @ObservedObject var weather = Weather.shared
    @AppStorage(K.expanded) private var expanded = false
    @AppStorage(K.hover) private var hover = true
    @AppStorage(K.shape) private var shape = "classic"
    @AppStorage(K.mode) private var mode = "island"
    @AppStorage(K.city) private var city = ""
    @State private var vol = 50.0

    var tint: Color { np.colors.first ?? .pink }
    var classic: Bool { shape == "classic" }

    var outline: AnyShape {
        classic
        ? AnyShape(UnevenRoundedRectangle(bottomLeadingRadius: expanded ? 36 : 28, bottomTrailingRadius: expanded ? 36 : 28, style: .continuous))
        : AnyShape(RoundedRectangle(cornerRadius: expanded ? 34 : 28, style: .continuous))
    }

    var body: some View {
        Group {
            if expanded { expandedView } else if classic { compactClassic } else { compactFloating }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
        .overlay(outline.stroke(LinearGradient(colors: [tint.opacity(np.isPlaying ? 0.55 : 0), .clear],
                                               startPoint: .bottom, endPoint: .top), lineWidth: 1.5))
        .clipShape(outline)
        .onHover { h in if hover { expanded = h } }
        .onAppear { vol = np.volume }
        .onChange(of: np.volume) { _, v in vol = v }
    }

    // MARK: compact

    /// Sits around the notch: art on the left ear, equalizer on the right, live lyric underneath.
    var compactClassic: some View {
        VStack(spacing: 0) {
            // Ear row: cover on the left of the notch, equalizer on the right, gap exactly as wide as the notch.
            HStack(spacing: 0) {
                CoverView(art: np.artwork, size: 22)
                    .padding(.leading, 16).frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: NotchInfo.width)
                EqualizerBars(tint: tint, height: 14)
                    .padding(.trailing, 16).frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: NotchInfo.height)
            // Live lyric sits below the notch.
            TimelineView(.periodic(from: .now, by: 0.2)) { ctx in
                Text(subtitle(ctx.date)).font(.system(size: 12, weight: .medium)).lineLimit(1)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 22).frame(height: 28)
        }
        .onTapGesture { expanded.toggle() }
    }

    var compactFloating: some View {
        HStack(spacing: 12) {
            CoverView(art: np.artwork, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(np.track?.title ?? "Nothing playing").font(.system(size: 13, weight: .semibold)).lineLimit(1)
                TimelineView(.periodic(from: .now, by: 0.2)) { ctx in
                    Text(subtitle(ctx.date)).font(.system(size: 11)).foregroundStyle(.white.opacity(0.65)).lineLimit(1)
                }
            }
            Spacer()
            EqualizerBars(tint: tint, height: 18)
        }
        .padding(.horizontal, 16).frame(maxHeight: .infinity)
        .onTapGesture { expanded.toggle() }
    }

    func subtitle(_ date: Date) -> String {
        let l = pair(date).0
        return l.isEmpty ? (np.track?.artist ?? "Play something in Spotify or Music") : l
    }

    func pair(_ date: Date) -> (String, String) {
        switch lyrics.state {
        case .synced(let lines):
            let i = lineIndex(lines, np.position(at: date) + lyrics.totalOffset)
            return (i >= 0 ? lines[i].text : "", i + 1 < lines.count ? lines[i + 1].text : "")
        case .loading: return ("Finding lyrics…", "")
        case .none: return ("No lyrics for this song", "")
        default: return ("", "")
        }
    }

    // MARK: expanded

    /// Top strip beside the notch: source on the left, weather + equalizer on the right.
    var earRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: np.track?.source == "Music" ? "applelogo" : "music.note.list")
                Text(np.track?.source ?? "Verse")
            }
            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
            .padding(.leading, 18).frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: NotchInfo.width)
            HStack(spacing: 8) {
                if let t = weather.temp, !city.isEmpty {
                    Image(systemName: weather.icon).font(.system(size: 11))
                    Text("\(t)°").font(.system(size: 12, weight: .semibold))
                }
                EqualizerBars(tint: tint, height: 12)
            }
            .padding(.trailing, 18).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: NotchInfo.height)
    }

    var expandedView: some View {
        VStack(spacing: 0) {
            if classic { earRow }
            expandedBody
        }
    }

    var expandedBody: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                CoverView(art: np.artwork, size: 84, radius: 16)
                VStack(alignment: .leading, spacing: 3) {
                    Text(np.track?.title ?? "Nothing playing").font(.system(size: 16, weight: .bold)).lineLimit(1)
                    Text(np.track?.artist ?? "Open Spotify or Music").font(.system(size: 13)).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                    Text(np.track?.album ?? "").font(.system(size: 11)).foregroundStyle(.white.opacity(0.45)).lineLimit(1)
                }
                Spacer()
                if !classic { EqualizerBars(tint: tint) }
            }
            TimelineView(.periodic(from: .now, by: 0.2)) { ctx in
                let p = pair(ctx.date)
                VStack(spacing: 3) {
                    Text(p.0).font(.system(size: 15, weight: .semibold)).lineLimit(2)
                    Text(p.1).font(.system(size: 12)).opacity(0.4).lineLimit(1)
                }
                .multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 50)
            }
            SeekBar(tint: tint)
            controls
            if weather.temp != nil && !city.isEmpty { weatherStrip }
        }
        .padding(.horizontal, 22).padding(.top, classic ? 6 : 22).padding(.bottom, 16)
    }

    var controls: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "speaker.fill").font(.system(size: 10))
                Slider(value: $vol, in: 0...100, onEditingChanged: { editing in
                    if !editing { np.setVolume(vol) }
                })
                .controlSize(.mini).frame(width: 80)
            }
            .frame(width: 120, alignment: .leading)
            Spacer()
            HStack(spacing: 24) {
                btn("backward.fill", 16) { np.command("previous track") }
                btn(np.isPlaying ? "pause.circle.fill" : "play.circle.fill", 32) { np.command("playpause") }
                btn("forward.fill", 16) { np.command("next track") }
            }
            Spacer()
            HStack(spacing: 14) {
                btn("text.quote", 14) { mode = "lyrics" }
                btn("photo.on.rectangle", 14) { Sharing.copyCard() }
                btn("gearshape", 14) { NotificationCenter.default.post(name: .verseSettings, object: nil) }
            }
            .frame(width: 120, alignment: .trailing)
        }
    }

    func btn(_ name: String, _ size: CGFloat, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: name).font(.system(size: size)) }.buttonStyle(.plain)
    }

    var weatherStrip: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Image(systemName: weather.icon)
                    Text("\(weather.temp ?? 0)°").font(.system(size: 18, weight: .semibold))
                }
                Text("\(weather.place) · ↑\(weather.hi ?? 0)° ↓\(weather.lo ?? 0)°")
                    .font(.system(size: 10)).opacity(0.55).lineLimit(1)
            }
            Spacer()
            ForEach(weather.hours) { h in
                VStack(spacing: 2) {
                    Text(h.label).font(.system(size: 9)).opacity(0.5)
                    Image(systemName: h.icon).font(.system(size: 11))
                    Text("\(h.temp)°").font(.system(size: 11, weight: .medium))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
