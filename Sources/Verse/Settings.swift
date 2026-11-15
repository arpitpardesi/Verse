import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab().tabItem { Label("General", systemImage: "gearshape") }
            LyricsTab().tabItem { Label("Lyrics", systemImage: "text.quote") }
            IslandTab().tabItem { Label("Island", systemImage: "capsule") }
            DiaryView().tabItem { Label("Diary", systemImage: "chart.bar") }
            AboutTab().tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 680, height: 580)
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
            Picker("Display", selection: $mode) {
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
            Section("Desktop") {
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
            ThemeBackground(theme: theme, setting: "auto", colors: [.purple, .blue, .pink], art: nil)
            SyncedLyrics(theme: theme, lines: Self.sample, index: 1, pos: 6, s: LStyle(scale: 0.3))
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

struct LyricsTab: View {
    @AppStorage(K.theme) private var theme = LyricTheme.bigWord.rawValue
    @AppStorage(K.background) private var bg = "auto"
    @AppStorage(K.font) private var font = "rounded"
    @AppStorage(K.align) private var align = "center"
    @AppStorage(K.accent) private var accent = "cover"
    @AppStorage(K.upper) private var upper = false
    @AppStorage(K.scale) private var scale = 1.0
    @AppStorage("globalOffset") private var globalOffset = 0.0
    @AppStorage(K.scatter) private var scatter = 0.5
    @AppStorage(K.lean) private var lean = 0.5

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

struct IslandTab: View {
    @AppStorage(K.shape) private var shape = "classic"
    @AppStorage(K.hover) private var hover = true
    @AppStorage(K.city) private var city = ""
    @AppStorage(K.unit) private var unit = "c"

    var body: some View {
        Form {
            Picker("Shape", selection: $shape) {
                Text("Notch (attached to top)").tag("classic")
                Text("Floating pill").tag("floating")
            }
            Toggle("Expand when the mouse hovers over it", isOn: $hover)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verse").font(.largeTitle.bold())
            Text("Free, open-source synced lyrics for your Mac notch.")
            Text("Lyrics: LRCLIB · Weather: Open-Meteo · Artwork: iTunes Search / Spotify")
                .font(.caption).foregroundStyle(.secondary)
            Text("Works with Spotify and Apple Music. macOS asks once for permission to read the current song.")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24).frame(maxWidth: .infinity, alignment: .leading)
    }
}
