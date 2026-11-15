import Foundation

/// Private listening diary stored only on this Mac.
@MainActor
final class Diary: ObservableObject {
    static let shared = Diary()
    struct Stat: Codable { var title: String; var artist: String; var seconds: Double; var plays: Int }
    struct Store: Codable {
        var daily: [String: Double] = [:]
        var artists: [String: Double] = [:]
        var tracks: [String: Stat] = [:]
    }
    @Published var data = Store()
    private var lastKey = ""
    private var unsaved = 0.0
    private let url = supportDir().appendingPathComponent("diary.json")
    private static let fmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f }()

    init() {
        if let d = try? Data(contentsOf: url), let s = try? JSONDecoder().decode(Store.self, from: d) { data = s }
    }

    func tick(_ t: Track?, playing: Bool, dt: Double) {
        guard let t, playing else { return }
        let key = "\(t.artist) — \(t.title)"
        if key != lastKey {
            lastKey = key
            var s = data.tracks[key] ?? Stat(title: t.title, artist: t.artist, seconds: 0, plays: 0)
            s.plays += 1
            data.tracks[key] = s
        }
        data.tracks[key]?.seconds += dt
        data.artists[t.artist, default: 0] += dt
        data.daily[Self.fmt.string(from: Date()), default: 0] += dt
        unsaved += dt
        if unsaved > 30 { save() }
    }

    func save() {
        unsaved = 0
        if let d = try? JSONEncoder().encode(data) { try? d.write(to: url) }
    }

    var today: Double { data.daily[Self.fmt.string(from: Date())] ?? 0 }
    var week: Double {
        (0..<7).reduce(0.0) { acc, i in
            let d = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            return acc + (data.daily[Self.fmt.string(from: d)] ?? 0)
        }
    }
    var total: Double { data.daily.values.reduce(0, +) }
    func topArtists(_ n: Int) -> [(String, Double)] {
        data.artists.sorted { $0.value > $1.value }.prefix(n).map { ($0.key, $0.value) }
    }
    func topTracks(_ n: Int) -> [(String, Double)] {
        data.tracks.values.sorted { $0.seconds > $1.seconds }.prefix(n).map { ("\($0.title) — \($0.artist)", $0.seconds) }
    }
}
