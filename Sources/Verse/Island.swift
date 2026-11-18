import SwiftUI
import AppKit

// MARK: - Animated Equalizer Bars

struct EqualizerBars: View {
    @ObservedObject var np = NowPlaying.shared
    var tint: Color
    var height: CGFloat = 20

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !np.isPlaying)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2.5) {
                ForEach(0..<4, id: \.self) { i in
                    let phase = t * (2.2 + Double(i) * 0.9) + Double(i) * 1.3
                    let h = np.isPlaying ? 0.2 + 0.8 * abs(sin(phase)) : 0.18
                    Capsule()
                        .fill(LinearGradient(colors: [tint, tint.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 2.8, height: max(3.5, height * CGFloat(h)))
                }
            }
            .frame(height: height, alignment: .bottom)
        }
    }
}

// MARK: - High-Precision Interactive Seek Bar

struct SeekBar: View {
    @ObservedObject var np = NowPlaying.shared
    var tint: Color
    var fg: Color = .white
    @State private var dragging: Double? = nil
    @State private var isHovering = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: np.isPlaying ? 0.25 : 2.0)) { ctx in
            let dur = max(np.track?.duration ?? 1, 1)
            let pos = dragging ?? min(np.position(at: ctx.date), dur)
            let progress = min(1.0, max(0.0, pos / dur))

            VStack(spacing: 3) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let barH: CGFloat = isHovering || dragging != nil ? 6 : 4
                    ZStack(alignment: .leading) {
                        // Trough
                        Capsule()
                            .fill(fg.opacity(0.14))
                            .frame(height: barH)

                        // Progress Fill
                        Capsule()
                            .fill(LinearGradient(colors: [tint.opacity(0.85), tint], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, w * CGFloat(progress)), height: barH)

                        // Luminous Playhead Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: isHovering || dragging != nil ? 12 : 8,
                                   height: isHovering || dragging != nil ? 12 : 8)
                            .shadow(color: tint.opacity(0.6), radius: 4)
                            .offset(x: max(0, min(w * CGFloat(progress) - (isHovering || dragging != nil ? 6 : 4), w - 10)))
                            .opacity(isHovering || dragging != nil ? 1 : 0.85)
                    }
                    .frame(height: 16)
                    .contentShape(Rectangle())
                    .onHover { h in withAnimation(.easeOut(duration: 0.15)) { isHovering = h } }
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            dragging = min(max(v.location.x / w, 0), 1) * dur
                        }
                        .onEnded { v in
                            np.seek(to: min(max(v.location.x / w, 0), 1) * dur)
                            dragging = nil
                        })
                }
                .frame(height: 16)

                // Elapsed and Remaining Timestamps
                HStack {
                    Text(fmtTime(pos))
                    Spacer()
                    Text("-" + fmtTime(max(0, dur - pos)))
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(fg.opacity(0.55))
            }
        }
    }
}

// MARK: - Bottom Edge Luminous Progress Line

struct ProgressLine: View {
    @ObservedObject var np = NowPlaying.shared
    var tint: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: np.isPlaying ? 0.35 : 4.0)) { ctx in
            let dur = max(np.track?.duration ?? 1, 1)
            let frac = min(1.0, max(0.0, np.position(at: ctx.date) / dur))
            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.09))
                    Capsule()
                        .fill(LinearGradient(colors: [tint.opacity(0.45), tint], startPoint: .leading, endPoint: .trailing))
                        .frame(width: w * CGFloat(frac))

                    // Gliding glowing lead dot
                    if np.isPlaying && frac > 0.01 && frac < 0.99 {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                            .shadow(color: tint, radius: 4)
                            .offset(x: max(0, w * CGFloat(frac) - 2))
                    }
                }
            }
            .frame(height: 2.2)
        }
    }
}

// MARK: - Peeking Vinyl Disc Visual

struct PeekingVinylDisc: View {
    @ObservedObject var np = NowPlaying.shared
    var size: CGFloat = 68

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !np.isPlaying)) { ctx in
            let angle = np.isPlaying ? np.position(at: ctx.date) * 90 : 0
            ZStack {
                // Vinyl Grooves
                Circle()
                    .fill(RadialGradient(colors: [Color(white: 0.16), Color(white: 0.05), .black], center: .center, startRadius: 0, endRadius: size / 2))
                    .frame(width: size, height: size)
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))

                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.8)
                        .padding(size * (0.06 + 0.07 * CGFloat(i)))
                }

                // Vinyl Center Label
                Circle()
                    .fill(np.colors.first ?? .pink)
                    .frame(width: size * 0.36, height: size * 0.36)
                    .overlay(Circle().fill(Color.black).frame(width: size * 0.08, height: size * 0.08))

                // Radial Gleam
                Circle()
                    .fill(AngularGradient(colors: [.clear, .white.opacity(0.12), .clear, .white.opacity(0.12), .clear], center: .center))
                    .allowsHitTesting(false)
            }
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.45), radius: 8, x: 2, y: 3)
        }
    }
}

// MARK: - Main Island View

struct IslandView: View {
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared
    @ObservedObject var weather = Weather.shared
    @ObservedObject var airpods = AirPodsMonitor.shared
    @AppStorage(K.expanded) private var expanded = false
    @AppStorage(K.hover) private var hover = true
    @AppStorage(K.shape) private var shape = "classic"
    @AppStorage(K.mode) private var mode = "island"
    @AppStorage(K.city) private var city = ""
    @AppStorage(K.artIsland) private var artIsland = true
    @AppStorage(K.artEffect) private var artEffect = "aura"
    @AppStorage(K.artDim) private var artDim = 0.45
    @State private var vol = 50.0
    @State private var hoverTask: Task<Void, Never>? = nil
    @State private var islandTab: Int = 0 // 0: Player & Lyrics, 1: Full Synced Stream, 2: Weather

    var tint: Color { np.colors.first ?? .pink }
    var classic: Bool { shape == "classic" }

    var outline: AnyShape {
        classic
        ? AnyShape(UnevenRoundedRectangle(bottomLeadingRadius: expanded ? 30 : 22, bottomTrailingRadius: expanded ? 30 : 22, style: .continuous))
        : AnyShape(RoundedRectangle(cornerRadius: expanded ? 30 : 24, style: .continuous))
    }

    var body: some View {
        Group {
            if expanded {
                expandedView
            } else if classic {
                compactClassic
            } else {
                compactFloating
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                // 1. Deep obsidian glass base
                Color(red: 0.05, green: 0.05, blue: 0.06).opacity(0.92)
                Rectangle().fill(.ultraThinMaterial)

                // 2. Ambient chromatic backlight glow from album artwork
                if np.isPlaying {
                    RadialGradient(
                        colors: [tint.opacity(0.35), tint.opacity(0.10), .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: expanded ? 340 : 160
                    )
                }

                // 3. Album artwork atmospheric wash in expanded mode
                if expanded && artIsland, let a = np.artwork {
                    ArtBackground(art: a, colors: np.colors, effect: artEffect, dim: max(artDim, 0.65), animated: false)
                }
            }
        }
        .overlay(
            outline.stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.32),
                        Color.white.opacity(0.08),
                        tint.opacity(np.isPlaying ? 0.45 : 0.05),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.2
            )
        )
        .clipShape(outline)
        .shadow(color: .black.opacity(expanded ? 0.55 : 0.35), radius: expanded ? 28 : 14, y: expanded ? 14 : 6)
        .shadow(color: tint.opacity(np.isPlaying ? (expanded ? 0.3 : 0.15) : 0), radius: expanded ? 32 : 12)
        .onHover { h in
            guard hover else { return }
            hoverTask?.cancel()
            hoverTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: h ? 120_000_000 : 220_000_000)
                if !Task.isCancelled { expanded = h }
            }
        }
        .onAppear { vol = np.volume }
        .onChange(of: np.volume) { _, v in vol = v }
    }

    // MARK: - Compact Classic (Physical MacBook Notch Integration)

    var compactClassic: some View {
        VStack(spacing: 0) {
            // Ear row: perfectly aligns with the MacBook notch cut-out
            HStack(spacing: 0) {
                // Left Ear: Rounded cover squircle with subtle specular border & ambient tint
                HStack(spacing: 6) {
                    CoverView(art: np.artwork, size: 24, radius: 6)
                        .shadow(color: tint.opacity(0.4), radius: 5)
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 0.8))
                }
                .padding(.leading, 14)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Exact physical notch cutout gap
                Color.clear.frame(width: NotchInfo.width)

                // Right Ear: Status Pill (AirPods / Weather) + Bouncy Audio Bars
                HStack(spacing: 7) {
                    if airpods.status.isConnected {
                        HStack(spacing: 3) {
                            Image(systemName: airpods.status.iconName)
                                .font(.system(size: 10, weight: .semibold))
                            if let pct = airpods.status.batteryPercentage {
                                Text("\(pct)%").font(.system(size: 9, weight: .bold, design: .rounded))
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.white.opacity(0.12), in: Capsule())
                        .foregroundStyle(.white.opacity(0.9))
                    } else if let t = weather.temp, !city.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: weather.icon).font(.system(size: 9))
                            Text("\(t)°").font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.white.opacity(0.12), in: Capsule())
                        .foregroundStyle(.white.opacity(0.9))
                    }

                    EqualizerBars(tint: tint, height: 13)
                }
                .padding(.trailing, 14)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: NotchInfo.height)

            // Live lyric line below the notch
            TimelineView(.periodic(from: .now, by: np.isPlaying ? 0.2 : 2.0)) { ctx in
                let sub = subtitle(ctx.date)
                HStack(spacing: 6) {
                    if case .synced = lyrics.state, np.isPlaying {
                        Circle()
                            .fill(tint)
                            .frame(width: 5, height: 5)
                            .shadow(color: tint, radius: 4)
                    }
                    Text(sub)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 22)
            .frame(height: 28)
        }
        .overlay(alignment: .bottom) {
            ProgressLine(tint: tint).padding(.horizontal, 22).padding(.bottom, 2.5)
        }
        .contentShape(Rectangle())
        .onTapGesture { expanded.toggle() }
    }

    // MARK: - Compact Floating Capsule (External Displays / Mini)

    var compactFloating: some View {
        HStack(spacing: 12) {
            CoverView(art: np.artwork, size: 36, radius: 9)
                .shadow(color: tint.opacity(0.45), radius: 6)
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.white.opacity(0.22), lineWidth: 0.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(np.track?.title ?? "Nothing playing")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                TimelineView(.periodic(from: .now, by: np.isPlaying ? 0.2 : 2.0)) { ctx in
                    HStack(spacing: 5) {
                        if case .synced = lyrics.state, np.isPlaying {
                            Circle().fill(tint).frame(width: 4, height: 4)
                        }
                        Text(subtitle(ctx.date))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 8)

            if airpods.status.isConnected {
                HStack(spacing: 3) {
                    Image(systemName: airpods.status.iconName)
                    if let pct = airpods.status.batteryPercentage {
                        Text("\(pct)%")
                    }
                }
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.12), in: Capsule())
                .foregroundStyle(.white.opacity(0.85))
            }

            EqualizerBars(tint: tint, height: 16)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            ProgressLine(tint: tint).padding(.horizontal, 20).padding(.bottom, 2.5)
        }
        .contentShape(Rectangle())
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

    // MARK: - Expanded Luxury Island

    var earRow: some View {
        HStack(spacing: 0) {
            // Source Badge Pill ( Music or Spotify)
            HStack(spacing: 5) {
                Image(systemName: np.track?.source == "Music" ? "applelogo" : "music.note")
                    .font(.system(size: 11, weight: .semibold))
                Text(np.track?.source ?? "Verse")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(np.track?.source == "Music" ? Color.pink : Color.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.8))
            .padding(.leading, 18)
            .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear.frame(width: NotchInfo.width)

            // Right Ear: Tab Switcher / AirPods Pill / Equalizer
            HStack(spacing: 8) {
                if airpods.status.isConnected {
                    HStack(spacing: 4) {
                        Image(systemName: airpods.status.iconName)
                        if let pct = airpods.status.batteryPercentage {
                            Text("\(pct)%").monospacedDigit()
                        }
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.12), in: Capsule())
                    .foregroundStyle(.white.opacity(0.9))
                }

                EqualizerBars(tint: tint, height: 13)
            }
            .padding(.trailing, 18)
            .frame(maxWidth: .infinity, alignment: .trailing)
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
            // Tab Selector (Music Player vs Full Lyrics vs Weather)
            HStack(spacing: 6) {
                tabButton(title: "Music", icon: "music.note", tag: 0)
                tabButton(title: "Lyrics", icon: "quote.bubble", tag: 1)
                if weather.temp != nil || !city.isEmpty {
                    tabButton(title: "Weather", icon: "cloud.sun.fill", tag: 2)
                }
                Spacer()
            }
            .padding(.horizontal, 2)

            // Content Switcher
            switch islandTab {
            case 1:
                fullLyricsStreamView
            case 2:
                weatherDetailView
            default:
                musicDetailView
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, classic ? 6 : 18)
        .padding(.bottom, 16)
        .gesture(DragGesture().onEnded { v in
            if v.translation.width < -35 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    islandTab = min(islandTab + 1, weather.temp != nil ? 2 : 1)
                }
            } else if v.translation.width > 35 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    islandTab = max(islandTab - 1, 0)
                }
            }
        })
    }

    func tabButton(title: String, icon: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { islandTab = tag }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                Text(title).font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(islandTab == tag ? tint.opacity(0.85) : Color.white.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(islandTab == tag ? 0.25 : 0.08), lineWidth: 0.8))
            .foregroundStyle(islandTab == tag ? Color.white : Color.white.opacity(0.6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Music Detail Tab

    var musicDetailView: some View {
        VStack(spacing: 12) {
            // Track Hero with Peeking Spinning Vinyl Disc
            HStack(spacing: 14) {
                ZStack(alignment: .leading) {
                    // Peeking Vinyl Disc
                    PeekingVinylDisc(size: 68)
                        .offset(x: np.isPlaying ? 28 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: np.isPlaying)

                    // Album Cover Jacket
                    CoverView(art: np.artwork, size: 76, radius: 14)
                        .shadow(color: tint.opacity(0.4), radius: 10, y: 5)
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.24), lineWidth: 1))
                }
                .frame(width: 106, height: 76, alignment: .leading)

                // Track Info
                VStack(alignment: .leading, spacing: 2.5) {
                    Text(np.track?.title ?? "Nothing playing")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(np.track?.artist ?? "Open Spotify or Music")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(tint.opacity(0.95))
                        .lineLimit(1)

                    if let album = np.track?.album, !album.isEmpty {
                        Text(album)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    // Format badge
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                        Text(np.track?.source == "Music" ? "Apple Lossless" : "High Quality")
                    }
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.top, 1)
                }

                Spacer()
            }

            // Frosted Live Lyrics Showcase Stage
            TimelineView(.periodic(from: .now, by: 0.2)) { ctx in
                let p = pair(ctx.date)
                VStack(spacing: 3) {
                    Text(p.0)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.white, tint.opacity(0.9), .white], startPoint: .leading, endPoint: .trailing))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .shadow(color: tint.opacity(0.45), radius: 8)

                    if !p.1.isEmpty {
                        Text(p.1)
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            }

            // Seek Bar
            SeekBar(tint: tint)

            // Deluxe Transport Dock & Controls
            controls
        }
    }

    // MARK: - Full Synced Stream Tab (In-Island Karaoke)

    @ViewBuilder
    private func lyricsStreamContent(date: Date) -> some View {
        if case .synced(let lines) = lyrics.state {
            let idx = lineIndex(lines, np.position(at: date) + lyrics.totalOffset)
            let start = max(0, idx - 1)
            let end = min(lines.count, idx + 3)

            VStack(spacing: 6) {
                ForEach(start..<end, id: \.self) { i in
                    let active = i == idx
                    Text(lines[i].text)
                        .font(.system(size: active ? 16 : 12, weight: active ? .bold : .medium, design: .rounded))
                        .foregroundStyle(active ? Color.white : Color.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .scaleEffect(active ? 1.05 : 0.98)
                        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: active)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 26))
                    .foregroundStyle(tint)
                Text(lyrics.state == .loading ? "Loading lyrics..." : "No synchronized lyrics available")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .frame(height: 120)
        }
    }

    var fullLyricsStreamView: some View {
        TimelineView(.periodic(from: .now, by: 0.2)) { ctx in
            lyricsStreamContent(date: ctx.date)
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 140)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
        }
    }

    // MARK: - Weather Detail Tab

    var weatherDetailView: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(weather.place.isEmpty ? (city.isEmpty ? "Local Weather" : city) : weather.place)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("Forecast & current conditions")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: weather.icon).font(.system(size: 24)).foregroundStyle(tint)
                    Text("\(weather.temp ?? 0)°")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
            }

            HStack(spacing: 16) {
                Label("High: \(weather.hi ?? 0)°", systemImage: "arrow.up")
                Label("Low: \(weather.lo ?? 0)°", systemImage: "arrow.down")
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))

            weatherStrip
        }
    }

    // MARK: - Deluxe Transport Controls

    var controls: some View {
        HStack(alignment: .center) {
            // Volume Pill
            HStack(spacing: 6) {
                Image(systemName: vol == 0 ? "speaker.slash.fill" : (vol < 50 ? "speaker.wave.1.fill" : "speaker.wave.3.fill"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))

                Slider(value: $vol, in: 0...100, onEditingChanged: { editing in
                    if !editing { np.setVolume(vol) }
                })
                .controlSize(.mini)
                .frame(width: 72)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08), in: Capsule())

            Spacer()

            // Center Floating Transport Capsule
            HStack(spacing: 20) {
                btn("backward.fill", 15) { np.command("previous track") }

                Button {
                    np.command("playpause")
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 38, height: 38)
                            .shadow(color: tint.opacity(0.55), radius: 8)

                        Image(systemName: np.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                btn("forward.fill", 15) { np.command("next track") }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.8))

            Spacer()

            // Tool Shortcuts
            HStack(spacing: 10) {
                btn("text.quote", 13) { mode = "lyrics" }
                btn("square.and.arrow.up", 13) { Sharing.copyCard() }
                btn("gearshape", 13) { NotificationCenter.default.post(name: .verseSettings, object: nil) }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08), in: Capsule())
        }
    }

    func btn(_ name: String, _ size: CGFloat, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var weatherStrip: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Image(systemName: weather.icon)
                    Text("\(weather.temp ?? 0)°").font(.system(size: 16, weight: .bold, design: .rounded))
                }
                Text("\(weather.place) • ↑\(weather.hi ?? 0)° ↓\(weather.lo ?? 0)°")
                    .font(.system(size: 9.5, design: .rounded)).opacity(0.6).lineLimit(1)
            }

            Spacer()

            ForEach(weather.hours) { h in
                VStack(spacing: 2) {
                    Text(h.label).font(.system(size: 8.5)).opacity(0.5)
                    Image(systemName: h.icon).font(.system(size: 10))
                    Text("\(h.temp)°").font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 0.8))
    }
}
