import Foundation

struct LyricLine: Identifiable, Equatable {
    let id: Int
    let time: Double
    let text: String
}

enum LyricsState {
    case idle, loading, none
    case plain(String)
    case synced([LyricLine])
}

func lineIndex(_ lines: [LyricLine], _ t: Double) -> Int {
    var lo = 0, hi = lines.count - 1, ans = -1
    while lo <= hi {
        let m = (lo + hi) / 2
        if lines[m].time <= t { ans = m; lo = m + 1 } else { hi = m - 1 }
    }
    return ans
}

func parseLRC(_ lrc: String) -> [LyricLine] {
    let re = try! NSRegularExpression(pattern: #"\[(\d+):(\d+(?:\.\d+)?)\]"#)
    var out: [(Double, String)] = []
    for raw in lrc.components(separatedBy: .newlines) {
        let ns = raw as NSString
        let matches = re.matches(in: raw, range: NSRange(location: 0, length: ns.length))
        guard let last = matches.last else { continue }
        let text = ns.substring(from: last.range.upperBound).trimmingCharacters(in: .whitespaces)
        for m in matches {
            let mins = Double(ns.substring(with: m.range(at: 1))) ?? 0
            let secs = Double(ns.substring(with: m.range(at: 2))) ?? 0
            out.append((mins * 60 + secs, text))
        }
    }
    return out.sorted { $0.0 < $1.0 }.enumerated().map { LyricLine(id: $0.offset, time: $0.element.0, text: $0.element.1) }
}

@MainActor
final class LyricsStore: ObservableObject {
    static let shared = LyricsStore()
    @Published var state: LyricsState = .idle
    /// Per-song sync offset in seconds (remembered).
    @Published var offset = 0.0 {
        didSet {
            guard !loadingOffset, !key.isEmpty else { return }
            var d = UserDefaults.standard.dictionary(forKey: "songOffsets") as? [String: Double] ?? [:]
            d[key] = offset
            UserDefaults.standard.set(d, forKey: "songOffsets")
        }
    }
    private var loadingOffset = false
    private var key = ""
    private var task: Task<Void, Never>?

    /// Per-song offset + global latency setting (e.g. Bluetooth headphones).
    var totalOffset: Double { offset + UserDefaults.standard.double(forKey: "globalOffset") }

    func nudge(_ d: Double) { offset = ((offset + d) * 10).rounded() / 10 }

    func load(_ track: Track?) {
        task?.cancel()
        guard let track else { state = .idle; return }
        key = "\(track.artist) — \(track.title)"
        loadingOffset = true
        offset = (UserDefaults.standard.dictionary(forKey: "songOffsets") as? [String: Double])?[key] ?? 0
        loadingOffset = false
        state = .loading
        task = Task {
            let result = await Self.fetch(track)
            if Task.isCancelled { return }
            if let s = result.0, !s.isEmpty { state = .synced(parseLRC(s)) }
            else if let p = result.1, !p.isEmpty { state = .plain(p) }
            else { state = .none }
        }
    }

    private struct Resp: Decodable { var syncedLyrics: String?; var plainLyrics: String?; var duration: Double? }

    private static func get<T: Decodable>(_ url: URL, as: T.Type) async -> T? {
        var req = URLRequest(url: url)
        req.setValue("Verse macOS lyrics app", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 10
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// Free, key-less synced lyrics from LRCLIB (lrclib.net).
    private static func fetch(_ t: Track) async -> (String?, String?) {
        var c = URLComponents(string: "https://lrclib.net/api/get")!
        c.queryItems = [
            .init(name: "track_name", value: t.title),
            .init(name: "artist_name", value: t.artist),
            .init(name: "album_name", value: t.album),
            .init(name: "duration", value: String(Int(t.duration.rounded())))
        ]
        if let r = await get(c.url!, as: Resp.self), r.syncedLyrics != nil || r.plainLyrics != nil {
            return (r.syncedLyrics, r.plainLyrics)
        }
        // Fallback search: pick the synced version whose length is closest to this track,
        // because lyrics timed for a different edit/length drift by seconds.
        var best: (Resp, Double)?
        var plain: String?
        for query in [[URLQueryItem(name: "track_name", value: t.title), URLQueryItem(name: "artist_name", value: t.artist)],
                      [URLQueryItem(name: "q", value: "\(t.artist) \(t.title)")]] {
            var s = URLComponents(string: "https://lrclib.net/api/search")!
            s.queryItems = query
            guard let list = await get(s.url!, as: [Resp].self) else { continue }
            for r in list {
                if plain == nil, let p = r.plainLyrics, !p.isEmpty { plain = p }
                guard let syn = r.syncedLyrics, !syn.isEmpty else { continue }
                let diff = abs((r.duration ?? t.duration) - t.duration)
                if best == nil || diff < best!.1 { best = (r, diff) }
            }
            if let b = best, b.1 <= 3 { break }
        }
        if let b = best, b.1 <= 6 { return (b.0.syncedLyrics, b.0.plainLyrics) }
        return (nil, plain)
    }
}

