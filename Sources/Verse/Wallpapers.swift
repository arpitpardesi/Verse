import SwiftUI
import AppKit

struct PaintedWallpaper: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let year: String
    let colors: [Color]
}

@MainActor
final class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()

    @Published var activeWallpaperID: String = ""
    @Published var autoCycle: String = "off" { // "off", "hourly", "daily", "track"
        didSet { UserDefaults.standard.set(autoCycle, forKey: "wallpaperAutoCycle") }
    }

    let gallery: [PaintedWallpaper] = [
        PaintedWallpaper(id: "starry_night", title: "The Starry Night", artist: "Vincent van Gogh", year: "1889",
                         colors: [Color(red: 0.10, green: 0.18, blue: 0.36), Color(red: 0.88, green: 0.72, blue: 0.20), Color(red: 0.22, green: 0.40, blue: 0.55)]),
        PaintedWallpaper(id: "water_lilies", title: "Water Lilies", artist: "Claude Monet", year: "1916",
                         colors: [Color(red: 0.15, green: 0.32, blue: 0.30), Color(red: 0.45, green: 0.55, blue: 0.42), Color(red: 0.75, green: 0.50, blue: 0.60)]),
        PaintedWallpaper(id: "great_wave", title: "The Great Wave off Kanagawa", artist: "Katsushika Hokusai", year: "1831",
                         colors: [Color(red: 0.08, green: 0.20, blue: 0.38), Color(red: 0.85, green: 0.82, blue: 0.75), Color(red: 0.30, green: 0.45, blue: 0.58)]),
        PaintedWallpaper(id: "wanderer", title: "Wanderer above the Sea of Fog", artist: "Caspar David Friedrich", year: "1818",
                         colors: [Color(red: 0.25, green: 0.30, blue: 0.35), Color(red: 0.65, green: 0.70, blue: 0.75), Color(red: 0.15, green: 0.18, blue: 0.22)]),
        PaintedWallpaper(id: "the_kiss", title: "The Kiss", artist: "Gustav Klimt", year: "1908",
                         colors: [Color(red: 0.78, green: 0.62, blue: 0.20), Color(red: 0.42, green: 0.25, blue: 0.15), Color(red: 0.88, green: 0.80, blue: 0.45)]),
        PaintedWallpaper(id: "pearl_earring", title: "Girl with a Pearl Earring", artist: "Johannes Vermeer", year: "1665",
                         colors: [Color(red: 0.12, green: 0.15, blue: 0.22), Color(red: 0.72, green: 0.55, blue: 0.38), Color(red: 0.28, green: 0.42, blue: 0.52)]),
        PaintedWallpaper(id: "sunrise", title: "Impression, Sunrise", artist: "Claude Monet", year: "1872",
                         colors: [Color(red: 0.85, green: 0.45, blue: 0.25), Color(red: 0.35, green: 0.45, blue: 0.55), Color(red: 0.20, green: 0.28, blue: 0.38)]),
        PaintedWallpaper(id: "composition_viii", title: "Composition VIII", artist: "Wassily Kandinsky", year: "1923",
                         colors: [Color(red: 0.85, green: 0.75, blue: 0.55), Color(red: 0.20, green: 0.35, blue: 0.60), Color(red: 0.80, green: 0.25, blue: 0.20)])
    ]

    private var cycleTimer: Timer?

    init() {
        self.autoCycle = UserDefaults.standard.string(forKey: "wallpaperAutoCycle") ?? "off"
        self.activeWallpaperID = UserDefaults.standard.string(forKey: "activeWallpaperID") ?? ""
        setupTimer()
    }

    private func setupTimer() {
        cycleTimer?.invalidate()
        guard autoCycle != "off" else { return }
        let interval: TimeInterval = autoCycle == "hourly" ? 3600 : 86400
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cycleNext()
            }
        }
        t.tolerance = 60.0
        cycleTimer = t
    }

    func cycleNext() {
        guard !gallery.isEmpty else { return }
        let currentIndex = gallery.firstIndex(where: { $0.id == activeWallpaperID }) ?? -1
        let nextIndex = (currentIndex + 1) % gallery.count
        setWallpaper(gallery[nextIndex])
    }

    func setWallpaper(_ wallpaper: PaintedWallpaper) {
        activeWallpaperID = wallpaper.id
        UserDefaults.standard.set(wallpaper.id, forKey: "activeWallpaperID")

        guard let screen = NSScreen.main else { return }
        Task.detached(priority: .userInitiated) {
            let fileURL = await self.renderWallpaperToFile(wallpaper, size: screen.frame.size)
            await MainActor.run {
                do {
                    try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: [:])
                    NSSound(named: "Pop")?.play()
                } catch {
                    print("Failed to set desktop wallpaper: \(error.localizedDescription)")
                }
            }
        }
    }

    private func renderWallpaperToFile(_ wallpaper: PaintedWallpaper, size: CGSize) -> URL {
        let dir = supportDir().appendingPathComponent("Wallpapers")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("\(wallpaper.id).png")

        let targetWidth = max(2560, Int(size.width * 2))
        let targetHeight = max(1440, Int(size.height * 2))

        let img = NSImage(size: NSSize(width: targetWidth, height: targetHeight))
        img.lockFocus()

        // Rich painterly background generation
        let c0 = NSColor(wallpaper.colors[0])
        let c1 = NSColor(wallpaper.colors[1 % wallpaper.colors.count])
        let c2 = NSColor(wallpaper.colors[2 % wallpaper.colors.count])

        let grad = NSGradient(colors: [c0, c1, c2])
        grad?.draw(in: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight), angle: 35)

        // Subtle oil-canvas texture overlay
        let context = NSGraphicsContext.current?.cgContext
        context?.setBlendMode(.overlay)
        for i in 0..<120 {
            let cx = CGFloat((i * 7919) % targetWidth)
            let cy = CGFloat((i * 104729) % targetHeight)
            let rad = CGFloat(100 + (i * 37) % 300)
            let col = (i % 2 == 0 ? c1 : c2).withAlphaComponent(0.08)
            col.setFill()
            context?.fillEllipse(in: CGRect(x: cx - rad, y: cy - rad, width: rad * 2, height: rad * 2))
        }

        img.unlockFocus()

        if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
           let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: fileURL)
        }

        return fileURL
    }
}

/// Gallery browser view for Settings and Menu Bar
struct WallpaperGalleryView: View {
    @ObservedObject var manager = WallpaperManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Curated Masterpieces")
                    .font(.headline)
                Spacer()
                Picker("Auto-cycle", selection: $manager.autoCycle) {
                    Text("Off").tag("off")
                    Text("Every Hour").tag("hourly")
                    Text("Daily").tag("daily")
                }
                .frame(width: 140)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                ForEach(manager.gallery) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(manager.activeWallpaperID == item.id ? Color.accentColor : Color.white.opacity(0.15), lineWidth: manager.activeWallpaperID == item.id ? 3 : 1)
                                )

                            if manager.activeWallpaperID == item.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white, Color.accentColor)
                                    .padding(8)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                            Text("\(item.artist) (\(item.year))")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        manager.setWallpaper(item)
                    }
                }
            }
        }
    }
}
