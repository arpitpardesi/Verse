import Foundation
import SwiftUI
import AppKit

public struct GitHubReleaseAsset: Decodable, Equatable {
    public let name: String
    public let size: Int?
    public let browser_download_url: String
}

public struct GitHubRelease: Decodable, Equatable {
    public let tag_name: String
    public let name: String?
    public let body: String?
    public let html_url: String
    public let published_at: String?
    public let assets: [GitHubReleaseAsset]
}

@MainActor
public final class UpdateManager: NSObject, ObservableObject {
    public static let shared = UpdateManager()

    public enum Status: Equatable {
        case idle
        case checking
        case upToDate(currentVersion: String, checkedAt: Date)
        case updateAvailable(release: GitHubRelease, currentVersion: String)
        case downloading(progress: Double, release: GitHubRelease)
        case readyToInstall(appURL: URL, release: GitHubRelease)
        case error(message: String)
    }

    @Published public var status: Status = .idle
    @Published public var hasUpdate: Bool = false
    @Published public var downloadProgress: Double = 0.0

    @Published public var autoCheck: Bool {
        didSet { UserDefaults.standard.set(autoCheck, forKey: "autoCheckUpdates") }
    }

    @Published public var lastCheckDate: Date? {
        didSet {
            if let d = lastCheckDate {
                UserDefaults.standard.set(d.timeIntervalSince1970, forKey: "lastUpdateCheckTimestamp")
            }
        }
    }

    public var currentVersion: String {
        if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !v.isEmpty {
            return v
        }
        if let v = Bundle.main.infoDictionary?["CFBundleVersion"] as? String, !v.isEmpty {
            return v
        }
        return "2.0"
    }

    private var activeDownloadRelease: GitHubRelease?
    private var downloadTask: URLSessionDownloadTask?
    private var activeDelegate: UpdateDownloadDelegate?

    override init() {
        let d = UserDefaults.standard
        let storedAuto = d.object(forKey: "autoCheckUpdates") as? Bool ?? true
        self.autoCheck = storedAuto

        let ts = d.double(forKey: "lastUpdateCheckTimestamp")
        if ts > 0 {
            self.lastCheckDate = Date(timeIntervalSince1970: ts)
        } else {
            self.lastCheckDate = nil
        }
        super.init()
    }

    /// Background check scheduled on app launch
    public func startAutoCheck() {
        guard autoCheck else { return }
        // Delay slightly after launch so it doesn't contend with startup audio/window setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            guard let self = self else { return }
            let now = Date()
            if let last = self.lastCheckDate, now.timeIntervalSince(last) < 43200 { // 12 hours throttling
                return
            }
            self.checkForUpdates(silent: true)
        }
    }

    /// Compare semantic versions (e.g. "v2.1" vs "2.0", "2.0.1" vs "2.0")
    public static func isVersion(_ remote: String, newerThan local: String) -> Bool {
        let cleanRemote = remote.trimmingCharacters(in: CharacterSet(charactersIn: "vV")).trimmingCharacters(in: .whitespaces)
        let cleanLocal = local.trimmingCharacters(in: CharacterSet(charactersIn: "vV")).trimmingCharacters(in: .whitespaces)

        let rParts = cleanRemote.split(separator: ".").compactMap { Int($0) }
        let lParts = cleanLocal.split(separator: ".").compactMap { Int($0) }

        let count = max(rParts.count, lParts.count)
        for i in 0..<count {
            let r = i < rParts.count ? rParts[i] : 0
            let l = i < lParts.count ? lParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }

    /// Query GitHub Releases API
    public func checkForUpdates(silent: Bool = false) {
        if !silent {
            status = .checking
        }

        Task {
            let release = await fetchLatestRelease()
            let now = Date()
            self.lastCheckDate = now

            guard let release = release else {
                if !silent {
                    self.status = .upToDate(currentVersion: self.currentVersion, checkedAt: now)
                }
                self.hasUpdate = false
                return
            }

            if Self.isVersion(release.tag_name, newerThan: self.currentVersion) {
                self.status = .updateAvailable(release: release, currentVersion: self.currentVersion)
                self.hasUpdate = true
            } else {
                self.status = .upToDate(currentVersion: self.currentVersion, checkedAt: now)
                self.hasUpdate = false
            }
        }
    }

    private func fetchLatestRelease() async -> GitHubRelease? {
        // Try releases/latest first
        if let rel = await fetchReleaseFromURL(URL(string: "https://api.github.com/repos/arpitpardesi/Verse/releases/latest")!) {
            return rel
        }
        // Fallback: fetch release list
        guard let listURL = URL(string: "https://api.github.com/repos/arpitpardesi/Verse/releases"),
              let (data, resp) = try? await URLSession.shared.data(from: listURL),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let releases = try? JSONDecoder().decode([GitHubRelease].self, from: data),
              let first = releases.first else {
            return nil
        }
        return first
    }

    private func fetchReleaseFromURL(_ url: URL) async -> GitHubRelease? {
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) else {
            return nil
        }
        return release
    }

    /// Download the release asset (.zip or .dmg)
    public func downloadUpdate(for release: GitHubRelease) {
        // Find zip asset first, then dmg
        let asset = release.assets.first(where: { $0.name.hasSuffix(".zip") }) ??
                    release.assets.first(where: { $0.name.hasSuffix(".dmg") }) ??
                    release.assets.first

        guard let asset = asset, let downloadURL = URL(string: asset.browser_download_url) else {
            // No direct binary asset attached: open release page
            if let webURL = URL(string: release.html_url) {
                NSWorkspace.shared.open(webURL)
            }
            return
        }

        self.activeDownloadRelease = release
        self.downloadProgress = 0.0
        self.status = .downloading(progress: 0.0, release: release)

        let delegate = UpdateDownloadDelegate(
            onProgress: { [weak self] progress in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.downloadProgress = progress
                    if let rel = self.activeDownloadRelease {
                        self.status = .downloading(progress: progress, release: rel)
                    }
                }
            },
            onFinish: { [weak self] location, originalURL in
                Task { @MainActor in
                    self?.handleDownloadFinished(location: location, originalURL: originalURL)
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.status = .error(message: "Download failed: \(error?.localizedDescription ?? "Network error")")
                }
            }
        )

        self.activeDelegate = delegate
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.downloadTask(with: downloadURL)
        self.downloadTask = task
        task.resume()
    }

    private func handleDownloadFinished(location: URL, originalURL: URL?) {
        guard let release = self.activeDownloadRelease else { return }

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("verse_update_\(UUID().uuidString)")
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let originalName = originalURL?.lastPathComponent ?? "VerseUpdate.zip"
        let destZip = tempDir.appendingPathComponent(originalName)

        do {
            try fileManager.moveItem(at: location, to: destZip)

            if originalName.hasSuffix(".zip") {
                // Extract using ditto
                let extractDir = tempDir.appendingPathComponent("extracted")
                try? fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)

                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                proc.arguments = ["-xk", destZip.path, extractDir.path]
                try proc.run()
                proc.waitUntilExit()

                // Locate Verse.app in extracted contents
                if let appURL = findApp(in: extractDir) {
                    self.status = .readyToInstall(appURL: appURL, release: release)
                    return
                }
            } else if originalName.hasSuffix(".dmg") {
                // Open DMG
                NSWorkspace.shared.open(destZip)
                self.status = .upToDate(currentVersion: self.currentVersion, checkedAt: Date())
                return
            }
        } catch {
            self.status = .error(message: "Extraction failed: \(error.localizedDescription)")
            return
        }

        // Fallback if app not found inside zip: open the extracted directory
        NSWorkspace.shared.open(tempDir)
        self.status = .upToDate(currentVersion: self.currentVersion, checkedAt: Date())
    }

    private func findApp(in directory: URL) -> URL? {
        let fm = FileManager.default
        if directory.lastPathComponent.hasSuffix(".app") { return directory }
        guard let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return nil
        }
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "Verse.app" {
                return fileURL
            }
        }
        return nil
    }

    /// Relaunch and install new version
    public func installAndRelaunch(appURL: URL) {
        let currentAppURL = Bundle.main.bundleURL
        let targetAppPath = currentAppURL.path
        let sourceAppPath = appURL.path
        let pid = ProcessInfo.processInfo.processIdentifier

        let script = """
        #!/bin/bash
        while kill -0 \(pid) 2>/dev/null; do
            sleep 0.2
        done
        rm -rf "\(targetAppPath)"
        cp -R "\(sourceAppPath)" "\(targetAppPath)"
        xattr -cr "\(targetAppPath)" 2>/dev/null || true
        open "\(targetAppPath)"
        """

        let scriptURL = FileManager.default.temporaryDirectory.appendingPathComponent("verse_updater.sh")
        try? script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments = ["+x", scriptURL.path]
        try? chmod.run()
        chmod.waitUntilExit()

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/bash")
        proc.arguments = [scriptURL.path]
        try? proc.run()

        NSApp.terminate(nil)
    }
}

final class UpdateDownloadDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
    private let onProgress: @Sendable (Double) -> Void
    private let onFinish: @Sendable (URL, URL?) -> Void
    private let onError: @Sendable (Error?) -> Void

    init(onProgress: @escaping @Sendable (Double) -> Void,
         onFinish: @escaping @Sendable (URL, URL?) -> Void,
         onError: @escaping @Sendable (Error?) -> Void) {
        self.onProgress = onProgress
        self.onFinish = onFinish
        self.onError = onError
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress(progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        onFinish(location, downloadTask.originalRequest?.url)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error { onError(error) }
    }
}

public struct UpdateCardView: View {
    @ObservedObject var updater = UpdateManager.shared
    @State private var showNotes = false

    private var formattedDate: String {
        guard let d = updater.lastCheckDate else { return "Never checked" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: d)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("Over-The-Air (OTA) Updates")
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.tertiary)
            }

            switch updater.status {
            case .idle, .upToDate:
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Verse is up to date")
                                .font(.system(size: 14, weight: .semibold))
                            Text("v\(updater.currentVersion)")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                                .foregroundStyle(.secondary)
                        }
                        Text("Last checked: \(formattedDate)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        updater.checkForUpdates()
                    } label: {
                        Label("Check Now", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

            case .checking:
                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking GitHub for newer releases...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)

            case .updateAvailable(let release, _):
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 38, height: 38)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text("New Version Available!")
                                    .font(.system(size: 15, weight: .bold))
                                Text(release.tag_name)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.pink.opacity(0.2), in: Capsule())
                                    .foregroundStyle(.pink)
                            }
                            if let name = release.name, !name.isEmpty {
                                Text(name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }

                    if let body = release.body, !body.isEmpty {
                        DisclosureGroup("What's New in \(release.tag_name)", isExpanded: $showNotes) {
                            ScrollView {
                                Text(body)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 4)
                            }
                            .frame(maxHeight: 120)
                        }
                        .font(.system(size: 12, weight: .medium))
                    }

                    HStack(spacing: 10) {
                        Button {
                            updater.downloadUpdate(for: release)
                        } label: {
                            Label("Download & Install", systemImage: "arrow.down.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        if let webURL = URL(string: release.html_url) {
                            Link(destination: webURL) {
                                Label("View on GitHub", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(14)
                .background(Color.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.pink.opacity(0.25), lineWidth: 1))

            case .downloading(let progress, let release):
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Downloading \(release.tag_name)...")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                }
                .padding(12)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))

            case .readyToInstall(let appURL, let release):
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(release.tag_name) is ready to install!")
                                .font(.system(size: 14, weight: .bold))
                            Text("Restart Verse to complete the update.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        updater.installAndRelaunch(appURL: appURL)
                    } label: {
                        Label("Restart & Install Now", systemImage: "arrow.clockwise.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(14)
                .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.25), lineWidth: 1))

            case .error(let message):
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        Button("Try Again") {
                            updater.checkForUpdates()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        if let url = URL(string: "https://github.com/arpitpardesi/Verse/releases") {
                            Link(destination: url) {
                                Label("Browse Releases", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            Toggle("Automatically check for updates daily", isOn: $updater.autoCheck)
                .toggleStyle(.checkbox)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}
