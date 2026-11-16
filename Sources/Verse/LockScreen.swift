import SwiftUI
import AppKit
import Combine

/// Lock Screen integration matching Needle:
/// Displays an interactive record player / live lyrics under the macOS lock screen clock.
@MainActor
final class LockScreenController: ObservableObject {
    static let shared = LockScreenController()

    @Published var isLocked: Bool = false
    @Published var mode: LockDisplayMode = .record
    private var lockPanel: NSPanel?
    private var bag = Set<AnyCancellable>()

    enum LockDisplayMode {
        case record
        case artwork
        case lyrics
    }

    init() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(handleScreenLocked),
                        name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        dnc.addObserver(self, selector: #selector(handleScreenUnlocked),
                        name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)

        NowPlaying.shared.$isPlaying
            .sink { [weak self] _ in self?.updatePanelVisibility() }
            .store(in: &bag)
    }

    @objc private func handleScreenLocked() {
        isLocked = true
        updatePanelVisibility()
    }

    @objc private func handleScreenUnlocked() {
        isLocked = false
        lockPanel?.orderOut(nil)
    }

    func updatePanelVisibility() {
        let enabled = UserDefaults.standard.object(forKey: "lockScreenEnabled") as? Bool ?? true
        guard isLocked && enabled && NowPlaying.shared.isPlaying else {
            lockPanel?.orderOut(nil)
            return
        }

        guard let screen = NSScreen.main else { return }
        if lockPanel == nil {
            let p = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let host = NSHostingView(rootView: LockScreenPlayerView())
            p.contentView = host
            lockPanel = p
        }

        // Center below the lock screen clock (approx 35% from the top)
        let sf = screen.frame
        let w: CGFloat = 400
        let h: CGFloat = 460
        let frame = NSRect(x: sf.midX - w / 2, y: sf.midY - h / 2 - 40, width: w, height: h)
        lockPanel?.setFrame(frame, display: true)
        lockPanel?.orderFrontRegardless()
    }

    func cycleMode() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            switch mode {
            case .record: mode = .artwork
            case .artwork: mode = .lyrics
            case .lyrics: mode = .record
            }
        }
    }
}

/// Interactive Lock Screen view: clicking flips between Vinyl, Artwork, and Synced Lyrics.
struct LockScreenPlayerView: View {
    @ObservedObject var lock = LockScreenController.shared
    @ObservedObject var np = NowPlaying.shared
    @ObservedObject var lyrics = LyricsStore.shared

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                switch lock.mode {
                case .record:
                    VStack(spacing: 12) {
                        RecordView(size: 260)
                            .shadow(color: .black.opacity(0.5), radius: 18, y: 8)
                        Text("Click to view artwork")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))

                case .artwork:
                    VStack(spacing: 12) {
                        CoverView(art: np.artwork, size: 260, radius: 24)
                            .shadow(color: (np.colors.first ?? .pink).opacity(0.4), radius: 24)
                        Text("Click to view live lyrics")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))

                case .lyrics:
                    VStack(spacing: 12) {
                        TimelineView(.periodic(from: .now, by: 0.15)) { ctx in
                            let pos = np.position(at: ctx.date) + lyrics.totalOffset
                            if case .synced(let lines) = lyrics.state {
                                let idx = lineIndex(lines, pos)
                                VStack(spacing: 8) {
                                    if idx >= 0, idx < lines.count {
                                        Text(lines[idx].text)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundStyle(np.colors.first ?? .pink)
                                            .multilineTextAlignment(.center)
                                            .shadow(color: (np.colors.first ?? .pink).opacity(0.6), radius: 10)
                                    }
                                    if idx + 1 < lines.count {
                                        Text(lines[idx + 1].text)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.4))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(24)
                                .frame(width: 320, height: 260)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            } else {
                                Text("♪")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(np.colors.first ?? .pink)
                            }
                        }
                        Text("Click to view turntable")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                lock.cycleMode()
            }

            // Track details under widget
            VStack(spacing: 3) {
                Text(np.track?.title ?? "Nothing playing")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(np.track?.artist ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .shadow(color: .black.opacity(0.7), radius: 6)
        }
        .padding(20)
    }
}
