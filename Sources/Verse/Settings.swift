import SwiftUI
import ServiceManagement

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, themes, art, glow, island, diary, about
    var id: String { rawValue }
    var title: String {
        switch self {
        case .general: return "General"
        case .themes: return "Lyric Themes"
        case .art: return "Album Art"
        case .glow: return "Edge Glow"
        case .island: return "Island"
        case .diary: return "Diary"
        case .about: return "About"
        }
    }
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .themes: return "textformat"
        case .art: return "photo.on.rectangle.angled"
        case .glow: return "sparkles"
        case .island: return "capsule"
        case .diary: return "chart.bar"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @State private var tab: SettingsTab? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $tab) { t in
                Label(t.title, systemImage: t.icon).tag(t)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 180, max: 200)
        } detail: {
            switch tab ?? .general {
            case .general: GeneralTab()
            case .themes: ThemesTab()
            case .art: ArtTab()
            case .glow: GlowTab()
            case .island: IslandTab()
            case .diary: DiaryView()
            case .about: AboutTab()
            }
        }
        .frame(width: 780, height: 600)
    }
}

struct GeneralTab: View {
    @AppStorage(K.mode) private var mode = "island"
    @AppStorage(K.glow) private var glow = false
    @AppStorage(K.record) private var record = false
    @AppStorage(K.recordStyle) private var recordStyle = "turntable"
    @State private var login = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Display") {
                Picker("View", selection: $mode) {
                    Text("Island (notch)").tag("island")
                    Text("Lyrics window").tag("lyrics")
                    Text("Full screen").tag("fullscreen")
                    Text("Desktop lyrics").tag("desktop")
                    Text("Hidden").tag("hidden")
                }
                Toggle("Launch at login", isOn: $login)
                    .onChange(of: login) { _, on in
                        if on { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
                    }
            }
            Section("Desktop extras") {
                Toggle("Edge glow (cover-coloured light around the screen)", isOn: $glow)
                Toggle("Record widget on desktop", isOn: $record)
                if record {
                    Picker("Widget style", selection: $recordStyle) {
                        Text("Turntable").tag("turntable")
                        Text("Record sleeve").tag("sleeve")
                        Text("Aura cover").tag("aura")
                    }
                }
            }
            Section("Tools") {
                Button("Copy lyric card of the current line") { Sharing.copyCard() }
                Button("Set wallpaper from album colours") { Sharing.setWallpaper() }
            }
        }
        .formStyle(.grouped)
    }
}

struct ThemeTile: View {
    let theme: LyricTheme
    let selected: Bool
    static let sample = [
        LyricLine(id: 0, time: 0, text: "Somewhere only we know"),
        LyricLine(id: 1, time: 4, text: "This could be the end"),
        LyricLine(id: 2, time: 8, text: "Of everything we've been")
    ]
    var body: some View {
        ZStack {
            ThemeBackground(theme: theme, setting: "auto", colors: [.purple, .blue, .pink], art: nil, animated: false)
            SyncedLyrics(theme: theme, lines: Self.sample, index: 1, pos: 6, s: LStyle(scale: 0.3), animated: false)
                .foregroundStyle(.white)
        }
        .frame(height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(selected ? Color.accentColor : Color.white.opacity(0.1), lineWidth: selected ? 3 : 1))
        .overlay(alignment: .bottomLeading) {
            Text(theme.title).font(.caption2.bold()).foregroundStyle(.white).padding(7)
        }
        .contentShape(Rectangle())
    }
}

struct ThemesTab: View {
    @AppStorage(K.theme) private var theme = LyricTheme.bigWord.rawValue
    @AppStorage(K.background) private var bg = "auto"
    @AppStorage(K.font) private var font = "rounded"
    @AppStorage(K.align) private var align = "center"
    @AppStorage(K.accent) private var accent = "cover"
    @AppStorage(K.upper) private var upper = false
    @AppStorage(K.scale) private var scale = 1.0
    @AppStorage(K.scatter) private var scatter = 0.5
    @AppStorage(K.lean) private var lean = 0.5
    @AppStorage("globalOffset") private var globalOffset = 0.0

    var body: some View {
        Form {
            Section("Theme") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    ForEach(LyricTheme.allCases) { th in
                        ThemeTile(theme: th, selected: theme == th.rawValue).onTapGesture { theme = th.rawValue }
                    }
                }
                .padding(.vertical, 4)
            }
            Section("Style") {
                Picker("Background", selection: $bg) {
                    Text("Theme default").tag("auto"); Text("Black").tag("black")
                    Text("Blurred cover").tag("cover"); Text("Glass").tag("glass")
                }
                Picker("Font", selection: $font) {
                    Text("Rounded").tag("rounded"); Text("Serif").tag("serif")
                    Text("Mono").tag("mono"); Text("System").tag("default")
                }
                Picker("Alignment", selection: $align) { Text("Center").tag("center"); Text("Left").tag("left") }
                Picker("Accent", selection: $accent) {
                    Text("From album art").tag("cover"); Text("Pink").tag("pink"); Text("Cyan").tag("cyan")
                    Text("Green").tag("green"); Text("Orange").tag("orange"); Text("White").tag("white")
                }
                Toggle("UPPERCASE", isOn: $upper)
                HStack { Text("Text size"); Slider(value: $scale, in: 0.6...1.6) }
                HStack { Text("Scatter"); Slider(value: $scatter, in: 0...1) }
                HStack { Text("Lean"); Slider(value: $lean, in: 0...1) }
            }
            Section("Sync") {
                HStack {
                    Text("Global lyrics delay")
                    Slider(value: $globalOffset, in: -5...5, step: 0.1)
                    Text(String(format: "%+.1fs", globalOffset)).monospacedDigit().frame(width: 52)
                }
                Text("Applies to every song. Use it for Bluetooth headphones or if all lyrics are early/late.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct ArtTab: View {
    @ObservedObject var np = NowPlaying.shared
    @AppStorage(K.artLyrics) private var artOn = true
    @AppStorage(K.artIsland) private var artIsland = true
    @AppStorage(K.artEffect) private var effect = "aura"
    @AppStorage(K.artDim) private var dim = 0.45

    var body: some View {
        let art = np.artwork ?? placeholderArt(np.colors)
        Form {
            Section("Show album art") {
                Toggle("Behind the lyrics (window and full screen)", isOn: $artOn)
                Toggle("Behind the expanded island", isOn: $artIsland)
            }
            Section("Effect") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(ArtEffect.allCases) { e in
                        ZStack {
                            Color.black
                            ArtBackground(art: art, colors: np.colors, effect: e.rawValue, dim: dim, animated: false)
                        }
                        .frame(height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(effect == e.rawValue ? Color.accentColor : Color.white.opacity(0.1),
                                    lineWidth: effect == e.rawValue ? 3 : 1))
                        .overlay(alignment: .bottomLeading) {
                            Text(e.title).font(.caption2.bold()).foregroundStyle(.white).padding(7)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { effect = e.rawValue }
                    }
                }
                .padding(.vertical, 4)
                HStack { Text("Darkness"); Slider(value: $dim, in: 0.1...0.9) }
                Text(np.artwork == nil ? "Previews use a sample cover until a song is playing." : "Previews use the current cover.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .disabled(!artOn && !artIsland)
        }
        .formStyle(.grouped)
    }
}

struct IslandTab: View {
    @AppStorage(K.shape) private var shape = "classic"
    @AppStorage(K.hover) private var hover = true
    @AppStorage(K.city) private var city = ""
    @AppStorage(K.unit) private var unit = "c"

    var body: some View {
        Form {
            Section("Island") {
                Picker("Shape", selection: $shape) {
                    Text("Notch (attached to top)").tag("classic")
                    Text("Floating pill").tag("floating")
                }
                Toggle("Expand when the mouse hovers over it", isOn: $hover)
            }
            Section("Weather (free, via Open-Meteo)") {
                TextField("City, e.g. Indore", text: $city)
                Picker("Units", selection: $unit) { Text("°C").tag("c"); Text("°F").tag("f") }
                    .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
    }
}

struct DiaryView: View {
    @ObservedObject var diary = Diary.shared

    func hm(_ s: Double) -> String {
        let m = Int(s) / 60
        return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m)m"
    }

    func stat(_ label: String, _ v: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(hm(v)).font(.title.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    func section(_ title: String, _ rows: [(String, Double)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            if rows.isEmpty { Text("Play some music and it will show up here.").foregroundStyle(.secondary) }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
                VStack(alignment: .leading, spacing: 2) {
                    HStack { Text(r.0).lineLimit(1); Spacer(); Text(hm(r.1)).foregroundStyle(.secondary) }
                    ProgressView(value: r.1, total: max(rows.first?.1 ?? 1, 1))
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) { stat("Today", diary.today); stat("This week", diary.week); stat("All time", diary.total) }
                section("Top artists", diary.topArtists(5))
                section("Top songs", diary.topTracks(5))
                Text("Stored only on this Mac in ~/Library/Application Support/Verse.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
}

struct AboutTab: View {
    private var appIcon: NSImage? {
        if let icon = NSApp.applicationIconImage, icon.isValid, icon.size.width > 32 {
            return icon
        }
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let img = NSImage(contentsOfFile: path) {
            return img
        }
        for rel in ["Resources/AppIcon-1024.png", "Resources/AppIcon.icns"] {
            if FileManager.default.fileExists(atPath: rel), let img = NSImage(contentsOfFile: rel) {
                return img
            }
        }
        return NSApp.applicationIconImage
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header with App Icon and Title
                HStack(alignment: .center, spacing: 20) {
                    if let icon = appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 84, height: 84)
                            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("Verse").font(.system(size: 26, weight: .bold))
                            Text("v2.0").font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                                .foregroundStyle(.secondary)
                        }
                        Text("Real-time synchronized lyrics & notch player for Mac")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Developer Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Created by").font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary).textCase(.uppercase)
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Arpit Pardesi").font(.system(size: 15, weight: .semibold))
                            Text("Developer & Creator").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let githubURL = URL(string: "https://github.com/arpitpardesi") {
                            Link(destination: githubURL) {
                                Label("GitHub Profile", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(14)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                }

                // Quick Links
                VStack(alignment: .leading, spacing: 10) {
                    Text("Project Links").font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary).textCase(.uppercase)
                    HStack(spacing: 10) {
                        if let repoURL = URL(string: "https://github.com/arpitpardesi/Verse") {
                            Link(destination: repoURL) {
                                Label("Source Code", systemImage: "curlybraces")
                            }
                        }
                        if let issuesURL = URL(string: "https://github.com/arpitpardesi/Verse/issues") {
                            Link(destination: issuesURL) {
                                Label("Report an Issue", systemImage: "ladybug")
                            }
                        }
                        if let emailURL = URL(string: "mailto:arpit.pardesi6@gmail.com") {
                            Link(destination: emailURL) {
                                Label("Contact", systemImage: "envelope")
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                // Acknowledgements & Data Sources
                VStack(alignment: .leading, spacing: 8) {
                    Text("Powered By").font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary).textCase(.uppercase)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("•").foregroundStyle(.secondary)
                            Text("Lyrics:").foregroundStyle(.secondary)
                            Link("LRCLIB", destination: URL(string: "https://lrclib.net")!)
                                .font(.system(size: 12, weight: .medium))
                            Text("— free, synchronized community lyrics database").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            Text("•").foregroundStyle(.secondary)
                            Text("Weather:").foregroundStyle(.secondary)
                            Link("Open-Meteo", destination: URL(string: "https://open-meteo.com")!)
                                .font(.system(size: 12, weight: .medium))
                            Text("— open-source weather forecasting API").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            Text("•").foregroundStyle(.secondary)
                            Text("Artwork:").foregroundStyle(.secondary)
                            Text("iTunes Search API & Spotify").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                    }
                    .font(.system(size: 12))
                }

                // Privacy & Open Source Note
                VStack(alignment: .leading, spacing: 4) {
                    Text("100% Local & Private")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Verse runs entirely on your Mac with zero telemetry, tracking, or accounts. Licensed under MIT.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))

                Spacer(minLength: 10)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
