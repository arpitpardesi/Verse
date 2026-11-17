import SwiftUI
import AppKit
import ScreenCaptureKit
import CoreMedia
import AudioToolbox

// MARK: - Live audio analysis (optional, needs Screen & System Audio Recording permission)

struct AudioSnapshot {
    var beatTimes: [Double] = []
    var level = 0.0, low = 0.0, mid = 0.0, high = 0.0
    var active = false
}

/// Listens to the system audio output (not the microphone) and detects bass beats.
/// Nothing is recorded or stored: each buffer is reduced to a few energy numbers and discarded.
final class AudioReactor: NSObject, SCStreamOutput, SCStreamDelegate {
    static let shared = AudioReactor()
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "verse.audio")
    private var stream: SCStream?
    private var running = false
    private var starting = false
    private var status = "Off"
    private var wasRunningBeforeSleep = false

    override init() {
        super.init()
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.lock.lock()
            let isRun = self.running
            self.lock.unlock()
            if isRun {
                self.wasRunningBeforeSleep = true
                self.stop()
            }
        }
        ws.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            if self.wasRunningBeforeSleep {
                self.wasRunningBeforeSleep = false
                let d = UserDefaults.standard
                if d.bool(forKey: K.glow) && (d.string(forKey: K.glowSync) ?? "audio") == "audio" {
                    self.start()
                }
            }
        }
    }
    // DSP state (audio queue only)
    private var lp1 = 0.0, lp2 = 0.0, avgLow = 1e-4
    private var peakAll = 1e-3, peakLow = 1e-3, peakMid = 1e-3, peakHigh = 1e-3
    // published state (guarded by lock)
    private var beats: [Double] = []
    private var level = 0.0, low = 0.0, mid = 0.0, high = 0.0
    private var lastSample = 0.0
    private var lastBeat = 0.0

    var statusText: String { lock.lock(); defer { lock.unlock() }; return status }
    private func setStatus(_ s: String) { lock.lock(); status = s; lock.unlock() }

    func snapshot() -> AudioSnapshot {
        lock.lock(); defer { lock.unlock() }
        let now = Date().timeIntervalSinceReferenceDate
        return AudioSnapshot(beatTimes: beats, level: level, low: low, mid: mid, high: high,
                             active: running && now - lastSample < 1.0)
    }

    private func storeStream(_ s: SCStream) { lock.withLock { stream = s } }

    private func finish(_ ok: Bool) { lock.lock(); starting = false; running = ok; lock.unlock() }

    func start() {
        lock.lock()
        if running || starting { lock.unlock(); return }
        starting = true
        lock.unlock()
        Task {
            guard CGPreflightScreenCaptureAccess() else {
                _ = CGRequestScreenCaptureAccess()
                setStatus("Waiting for permission. Allow Verse under System Settings → Privacy & Security → Screen & System Audio Recording, then relaunch Verse.")
                finish(false)
                return
            }
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = content.displays.first else { setStatus("No display found."); finish(false); return }
                let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
                let cfg = SCStreamConfiguration()
                cfg.capturesAudio = true
                cfg.excludesCurrentProcessAudio = true
                cfg.sampleRate = 44100
                cfg.channelCount = 2
                cfg.width = 64
                cfg.height = 64
                cfg.minimumFrameInterval = CMTime(value: 1, timescale: 2)
                let s = SCStream(filter: filter, configuration: cfg, delegate: self)
                try s.addStreamOutput(self, type: .audio, sampleHandlerQueue: queue)
                try await s.startCapture()
                storeStream(s)
                setStatus("Listening to system audio")
                finish(true)
            } catch {
                setStatus("Audio capture failed: \(error.localizedDescription)")
                finish(false)
            }
        }
    }

    func stop() {
        lock.lock()
        let s = stream
        stream = nil; running = false; starting = false; status = "Off"
        lock.unlock()
        if let s { Task { try? await s.stopCapture() } }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        lock.lock(); running = false; starting = false; status = "Stopped: \(error.localizedDescription)"; lock.unlock()
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, sampleBuffer.isValid else { return }
        var blockBuffer: CMBlockBuffer?
        let ablSize = MemoryLayout<AudioBufferList>.size + MemoryLayout<AudioBuffer>.size * 2
        let raw = UnsafeMutableRawPointer.allocate(byteCount: ablSize, alignment: 16)
        defer { raw.deallocate() }
        let ablPtr = raw.bindMemory(to: AudioBufferList.self, capacity: 1)
        var needed = 0
        let st = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer, bufferListSizeNeededOut: &needed, bufferListOut: ablPtr, bufferListSize: ablSize,
            blockBufferAllocator: nil, blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, blockBufferOut: &blockBuffer)
        guard st == noErr else { return }
        let list = UnsafeMutableAudioBufferListPointer(ablPtr)
        guard let first = list.first, let data = first.mData else { return }
        let n = Int(first.mDataByteSize) / MemoryLayout<Float>.size
        guard n > 0 else { return }
        process(data.assumingMemoryBound(to: Float.self), n)
        _ = blockBuffer
    }

    private func process(_ p: UnsafePointer<Float>, _ n: Int) {
        let a1 = 0.028   // ~200 Hz low-pass at 44.1 kHz
        let a2 = 0.25    // ~2 kHz low-pass
        var eAll = 0.0, eLow = 0.0, eMid = 0.0, eHigh = 0.0
        for i in 0..<n {
            let x = Double(p[i])
            lp1 += a1 * (x - lp1)
            lp2 += a2 * (x - lp2)
            let l = lp1, m = lp2 - lp1, h = x - lp2
            eAll += x * x; eLow += l * l; eMid += m * m; eHigh += h * h
        }
        let inv = 1.0 / Double(n)
        eAll *= inv; eLow *= inv; eMid *= inv; eHigh *= inv
        let rms = sqrt(eAll), rl = sqrt(eLow), rm = sqrt(eMid), rh = sqrt(eHigh)
        peakAll = max(peakAll * 0.9997, rms, 1e-4)
        peakLow = max(peakLow * 0.9997, rl, 1e-4)
        peakMid = max(peakMid * 0.9997, rm, 1e-4)
        peakHigh = max(peakHigh * 0.9997, rh, 1e-4)
        avgLow = avgLow * 0.98 + eLow * 0.02
        let now = Date().timeIntervalSinceReferenceDate
        lock.lock()
        level = max(level * 0.88, min(1, rms / peakAll))
        low = max(low * 0.86, min(1, rl / peakLow))
        mid = max(mid * 0.86, min(1, rm / peakMid))
        high = max(high * 0.86, min(1, rh / peakHigh))
        lastSample = now
        if eLow > avgLow * 1.5 + 1e-7, eLow > 2e-5, now - lastBeat > 0.25 {
            lastBeat = now
            beats.append(now)
            if beats.count > 4 { beats.removeFirst() }
        }
        lock.unlock()
    }
}

// MARK: - Beat source used by the glow

struct BeatSample {
    var ages: [Double]       // seconds since the most recent beats, newest first
    var level: Double
    var low: Double
    var mid: Double
    var high: Double
}

private final class PulseBox { var idx = -2; var t = 0.0 }

struct EdgeGlowView: View {
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared
    @AppStorage(K.glowStyle) private var style = "border"
    @AppStorage(K.glowSync) private var sync = "audio"
    @AppStorage(K.glowColor) private var colorKey = "cover"
    @AppStorage(K.glowIntensity) private var intensity = 0.8
    @AppStorage(K.glowWidth) private var width = 6.0
    @AppStorage(K.glowBPM) private var bpm = 100.0
    @AppStorage(K.glowSens) private var sens = 1.0
    @State private var box = PulseBox()

    var cols: [Color] {
        switch colorKey {
        case "rainbow": return [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]
        case "cover": return np.colors
        default:
            let c = verseAccent(colorKey, np.colors)
            return [c, c.opacity(0.7), c]
        }
    }

    func sample(_ now: Date) -> BeatSample {
        let t = now.timeIntervalSinceReferenceDate
        guard np.isPlaying else { return BeatSample(ages: [], level: 0.06, low: 0.05, mid: 0.05, high: 0.05) }
        var mode = sync
        let snap = AudioReactor.shared.snapshot()
        if mode == "audio" && !snap.active { mode = "bpm" }   // falls back until audio is available
        switch mode {
        case "audio":
            let g = sens
            let ages = snap.beatTimes.map { t - $0 }.filter { $0 >= 0 && $0 < 2 }.sorted()
            return BeatSample(ages: ages, level: min(1, snap.level * g), low: min(1, snap.low * g),
                              mid: min(1, snap.mid * g), high: min(1, snap.high * g))
        case "lyrics":
            var idx = -1
            if case .synced(let lines) = lyrics.state { idx = lineIndex(lines, np.position(at: now) + lyrics.totalOffset) }
            if idx != box.idx { box.idx = idx; box.t = t }
            let age = t - box.t
            let k = exp(-age * 2.5)
            return BeatSample(ages: [age], level: 0.3 + 0.5 * k, low: k, mid: 0.4 + 0.3 * sin(t * 2), high: 0.35 + 0.3 * sin(t * 3.1))
        case "smooth":
            let age = t.truncatingRemainder(dividingBy: 2.4)
            let k = exp(-age * 1.5)
            return BeatSample(ages: [age], level: 0.3 + 0.4 * k, low: k, mid: 0.5 + 0.3 * sin(t * 1.3), high: 0.4 + 0.3 * sin(t * 2.2))
        default:
            let period = 60 / max(bpm, 30)
            let ph = np.position(at: now).truncatingRemainder(dividingBy: period)
            let k = exp(-ph * 7)
            return BeatSample(ages: [ph, ph + period, ph + 2 * period], level: 0.35 + 0.45 * k, low: k,
                              mid: 0.45 + 0.3 * sin(t * 2.1), high: 0.4 + 0.3 * sin(t * 3.3))
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: PowerOptimizer.shared.isLowPowerMode ? 1.0 / 20 : 1.0 / 30, paused: !np.isPlaying)) { ctx in
            let smp = sample(ctx.date)
            let t = ctx.date.timeIntervalSinceReferenceDate
            Canvas { c, sz in
                GlowRenderer.draw(&c, size: sz, style: style, cols: cols, smp: smp, t: t,
                                  intensity: intensity, width: width)
            }
        }
        .allowsHitTesting(false)
    }
}

@MainActor
enum GlowRenderer {
    static func draw(_ c: inout GraphicsContext, size: CGSize, style: String, cols: [Color],
                     smp: BeatSample, t: Double, intensity: Double, width: Double) {
        guard !cols.isEmpty else { return }
        func col(_ i: Int) -> Color { cols[((i % cols.count) + cols.count) % cols.count] }
        let pulse = smp.ages.first.map { exp(-$0 * 7) } ?? 0
        let power = intensity * (0.35 + 0.65 * max(pulse, smp.level * 0.6))
        let rect = CGRect(origin: .zero, size: size)
        let w = CGFloat(width)

        switch style {
        case "rim":
            let path = Path(roundedRect: rect, cornerRadius: 24)
            let speed = 70.0 + 40.0 * smp.level
            let angle = (t * speed).truncatingRemainder(dividingBy: 360.0)

            // Background ambient resting rim
            c.stroke(path, with: .color(col(0).opacity(0.18 * power)), lineWidth: w * 0.8)

            // Dynamic circulating gradient wave
            let rimColors = [
                col(0).opacity(0.1),
                col(1).opacity(0.35),
                col(2).opacity(0.85),
                Color.white.opacity(0.98), // Leading comet head of the wave
                col(0).opacity(0.95),
                col(1).opacity(0.35),
                col(0).opacity(0.1)
            ]
            let conic = GraphicsContext.Shading.conicGradient(
                Gradient(colors: rimColors),
                center: CGPoint(x: size.width / 2, y: size.height / 2),
                angle: .degrees(angle)
            )

            // Multi-tier bloom layers on the rim (simplified to single tier on Low Power Mode)
            let rimWidths: [CGFloat] = [w * (1.0 + 0.9 * CGFloat(pulse)), w * (2.4 + 1.2 * CGFloat(pulse)), w * (4.5 + 2.0 * CGFloat(pulse))]
            let rimOpacities: [Double] = [min(1.0, power * 1.4), min(0.7, power * 0.55), min(0.4, power * 0.28)]
            let tierCount = PowerOptimizer.shared.isLowPowerMode ? 1 : 3

            for k in 0..<tierCount {
                c.drawLayer { l in
                    l.opacity = rimOpacities[k]
                    l.stroke(path, with: conic, lineWidth: rimWidths[k])
                }
            }

        case "ripple":
            for age in smp.ages where age < 1.1 {
                let inset = CGFloat(age) * 240
                let k = max(0, 1 - age / 1.1)
                let r = rect.insetBy(dx: inset, dy: inset * size.height / max(size.width, 1))
                guard r.width > 20, r.height > 20 else { continue }
                c.stroke(Path(roundedRect: r, cornerRadius: 22 + inset * 0.25),
                         with: .color(col(Int(age * 3)).opacity(k * intensity)),
                         lineWidth: w * CGFloat(0.6 + k))
            }
            c.stroke(Path(roundedRect: rect, cornerRadius: 22), with: .color(col(0).opacity(0.25 * power)), lineWidth: w)

        case "spectrum":
            let n = 72
            let bw = size.width / CGFloat(n)
            for i in 0..<n {
                let f = Double(i) / Double(n - 1)
                let band = f < 0.33 ? smp.low : (f < 0.66 ? smp.mid : smp.high)
                let wobPhase = t * (1.5 + f * 3) + Double(i) * 0.7
                let wob = 0.5 + 0.5 * abs(sin(wobPhase))
                let reach = (50 + width * 10) * band * wob * intensity
                let h = CGFloat(4 + reach)
                let color = col(Int(f * Double(cols.count - 1) + 0.5)).opacity(0.5 + 0.4 * intensity)
                let x = CGFloat(i) * bw + bw * 0.18
                c.fill(Path(roundedRect: CGRect(x: x, y: size.height - h, width: bw * 0.64, height: h), cornerRadius: bw * 0.3),
                       with: .color(color))
                c.fill(Path(roundedRect: CGRect(x: x, y: 0, width: bw * 0.64, height: h * 0.6), cornerRadius: bw * 0.3),
                       with: .color(color.opacity(0.6)))
            }

        case "corners":
            let r = CGFloat(180 + width * 14) + CGFloat(pulse) * 260
            let pts = [CGPoint.zero, CGPoint(x: size.width, y: 0), CGPoint(x: 0, y: size.height), CGPoint(x: size.width, y: size.height)]
            for (i, p) in pts.enumerated() {
                c.fill(Path(rect),
                       with: .radialGradient(Gradient(colors: [col(i).opacity(min(1, 0.85 * power)), .clear]),
                                             center: p, startRadius: 0, endRadius: r))
            }

        case "aurora":
            let h = size.height * CGFloat(0.08 + 0.2 * smp.level) + CGFloat(pulse) * 90 * CGFloat(width / 6)
            for j in 0..<3 {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: size.height))
                var x: CGFloat = 0
                while x <= size.width + 10 {
                    let jd = Double(j)
                    let ph = Double(x) / 220 + t * (0.7 + jd * 0.35) + jd * 1.9
                    let k = CGFloat(0.65 + 0.35 * sin(ph))
                    p.addLine(to: CGPoint(x: x, y: size.height - h * k))
                    x += 10
                }
                p.addLine(to: CGPoint(x: size.width, y: size.height))
                p.closeSubpath()
                c.fill(p, with: .linearGradient(Gradient(colors: [col(j).opacity(min(1, 0.8 * power)), .clear]),
                                                startPoint: CGPoint(x: 0, y: size.height),
                                                endPoint: CGPoint(x: 0, y: size.height - h * 1.1)))
            }

        default: // border
            let path = Path(roundedRect: rect, cornerRadius: 22)
            let grad = GraphicsContext.Shading.conicGradient(Gradient(colors: cols + [cols[0]]),
                                                             center: CGPoint(x: size.width / 2, y: size.height / 2),
                                                             angle: .degrees(t * 40))
            let widths: [Double] = [1, 2.6, 4.2, 5.8]
            let alphas: [Double] = [0.9, 0.35, 0.18, 0.09]
            for k in 0..<4 {
                let lw = CGFloat(width * widths[k] * (1 + 0.8 * pulse))
                let op = min(1, power * alphas[k] * 1.3)
                c.drawLayer { l in
                    l.opacity = op
                    l.stroke(path, with: grad, lineWidth: lw)
                }
            }
        }
    }
}

// MARK: - Settings tab

struct GlowTab: View {
    @AppStorage(K.glow) private var glow = false
    @AppStorage(K.glowStyle) private var style = "border"
    @AppStorage(K.glowSync) private var sync = "audio"
    @AppStorage(K.glowColor) private var colorKey = "cover"
    @AppStorage(K.glowIntensity) private var intensity = 0.8
    @AppStorage(K.glowWidth) private var width = 6.0
    @AppStorage(K.glowBPM) private var bpm = 100.0
    @AppStorage(K.glowSens) private var sens = 1.0

    var body: some View {
        Form {
            Section("Edge glow") {
                Toggle("Show edge glow", isOn: $glow)
                Picker("Style", selection: $style) {
                    Text("Beat Glow Rim (Needle wave)").tag("rim")
                    Text("Border glow").tag("border")
                    Text("Ripple (rings from the edge)").tag("ripple")
                    Text("Spectrum bars").tag("spectrum")
                    Text("Corner flares").tag("corners")
                    Text("Aurora (rises from the bottom)").tag("aurora")
                }
                Picker("Colours", selection: $colorKey) {
                    Text("From album art").tag("cover"); Text("Rainbow").tag("rainbow")
                    Text("Pink").tag("pink"); Text("Cyan").tag("cyan"); Text("Green").tag("green")
                    Text("Orange").tag("orange"); Text("White").tag("white")
                }
                HStack { Text("Intensity"); Slider(value: $intensity, in: 0.2...1) }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Thickness")
                        Slider(value: $width, in: 1...30, step: 1)
                        Text("\(Int(width)) pt").monospacedDigit().frame(width: 48)
                    }
                    HStack(spacing: 8) {
                        Text("Presets:").font(.caption).foregroundStyle(.secondary)
                        Button("Hairline (2 pt)") { width = 2 }
                        Button("Normal (6 pt)") { width = 6 }
                        Button("Bold (12 pt)") { width = 12 }
                        Button("Massive (24 pt)") { width = 24 }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            Section("Beat sync") {
                Picker("Sync to", selection: $sync) {
                    Text("Live audio (beat detection)").tag("audio")
                    Text("Tempo (BPM)").tag("bpm")
                    Text("Lyric lines").tag("lyrics")
                    Text("Gentle breathing").tag("smooth")
                }
                if sync == "bpm" {
                    HStack {
                        Text("Tempo"); Slider(value: $bpm, in: 60...180, step: 1)
                        Text("\(Int(bpm)) BPM").monospacedDigit().frame(width: 70)
                    }
                    Text("Beats are counted from the start of the song, so pick the song's BPM for the best match.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if sync == "audio" {
                    HStack { Text("Sensitivity"); Slider(value: $sens, in: 0.5...3) }
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        let active = AudioReactor.shared.snapshot().active
                        VStack(alignment: .leading, spacing: 6) {
                            Label(active ? "Receiving audio" : "Not receiving audio yet (using tempo pulse meanwhile)",
                                  systemImage: active ? "waveform" : "waveform.slash")
                            Text(AudioReactor.shared.statusText).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Button("Request permission") { _ = CGRequestScreenCaptureAccess() }
                        Button("Open Privacy Settings") {
                            if let u = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                                NSWorkspace.shared.open(u)
                            }
                        }
                        Button("Retry") { AudioReactor.shared.start() }
                    }
                    Text("Live sync listens to your Mac's audio output (not the microphone) to detect bass hits. It needs the Screen & System Audio Recording permission, and macOS asks you to relaunch Verse after you allow it. Nothing is recorded or saved.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}
