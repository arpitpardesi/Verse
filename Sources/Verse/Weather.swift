import Foundation

/// Weather from Open-Meteo (free, no API key). Set a city in Settings → Island.
@MainActor
final class Weather: ObservableObject {
    static let shared = Weather()
    struct Hour: Identifiable { let id: Int; let label: String; let temp: Int; let icon: String }
    @Published var temp: Int?
    @Published var icon = "cloud"
    @Published var hi: Int?
    @Published var lo: Int?
    @Published var hours: [Hour] = []
    @Published var place = ""
    private var timer: Timer?
    private var sig = ""

    func start() {
        refresh()
        let t = Timer.scheduledTimer(withTimeInterval: 1200, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        t.tolerance = 60.0
        timer = t
    }

    func refreshIfNeeded() {
        let d = UserDefaults.standard
        let s = (d.string(forKey: K.city) ?? "") + "|" + (d.string(forKey: K.unit) ?? "c")
        if s != sig { refresh() }
    }

    func refresh() { Task { await load() } }

    static func symbol(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61...67: return "cloud.rain.fill"
        case 71...77: return "cloud.snow.fill"
        case 80...82: return "cloud.heavyrain.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    private struct Geo: Decodable {
        struct R: Decodable { var latitude: Double; var longitude: Double; var name: String }
        var results: [R]?
    }
    private struct Forecast: Decodable {
        struct Cur: Decodable { var time: String; var temperature_2m: Double; var weather_code: Int }
        struct Hr: Decodable { var time: [String]; var temperature_2m: [Double]; var weather_code: [Int] }
        struct Dy: Decodable { var temperature_2m_max: [Double]; var temperature_2m_min: [Double] }
        var current: Cur; var hourly: Hr; var daily: Dy
    }

    private func load() async {
        let d = UserDefaults.standard
        let city = (d.string(forKey: K.city) ?? "").trimmingCharacters(in: .whitespaces)
        let unit = d.string(forKey: K.unit) ?? "c"
        sig = city + "|" + unit
        guard !city.isEmpty else { temp = nil; hours = []; place = ""; return }

        var g = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        g.queryItems = [.init(name: "name", value: city), .init(name: "count", value: "1")]
        guard let (gd, _) = try? await URLSession.shared.data(from: g.url!),
              let geo = try? JSONDecoder().decode(Geo.self, from: gd),
              let r = geo.results?.first else { place = "City not found"; temp = nil; return }

        var f = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        f.queryItems = [
            .init(name: "latitude", value: String(r.latitude)),
            .init(name: "longitude", value: String(r.longitude)),
            .init(name: "current", value: "temperature_2m,weather_code"),
            .init(name: "hourly", value: "temperature_2m,weather_code"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            .init(name: "forecast_days", value: "2"),
            .init(name: "timezone", value: "auto"),
            .init(name: "temperature_unit", value: unit == "f" ? "fahrenheit" : "celsius")
        ]
        guard let (fd, _) = try? await URLSession.shared.data(from: f.url!),
              let fc = try? JSONDecoder().decode(Forecast.self, from: fd) else { return }
        place = r.name
        temp = Int(fc.current.temperature_2m.rounded())
        icon = Self.symbol(fc.current.weather_code)
        hi = fc.daily.temperature_2m_max.first.map { Int($0.rounded()) }
        lo = fc.daily.temperature_2m_min.first.map { Int($0.rounded()) }
        let idx = fc.hourly.time.firstIndex { $0.prefix(13) == fc.current.time.prefix(13) } ?? 0
        var hs: [Hour] = []
        for k in 1...6 where idx + k < fc.hourly.time.count {
            let i = idx + k
            hs.append(Hour(id: i, label: String(fc.hourly.time[i].suffix(5)),
                           temp: Int(fc.hourly.temperature_2m[i].rounded()),
                           icon: Self.symbol(fc.hourly.weather_code[i])))
        }
        hours = hs
    }
}
