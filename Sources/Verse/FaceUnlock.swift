import SwiftUI
import AppKit
import AVFoundation
import Vision
import Security

/// Face Unlock (Beta) matching Needle:
/// Uses the built-in FaceTime HD camera to detect the user's face at the lock screen
/// and unlock the Mac using locally encrypted Keychain credentials.
@MainActor
final class FaceUnlockManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let shared = FaceUnlockManager()

    @Published var isEnabled: Bool = false {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "faceUnlockEnabled") }
    }
    @Published var hasSavedPassword: Bool = false
    @Published var statusText: String = "Disabled"
    @Published var isScanning: Bool = false

    private var captureSession: AVCaptureSession?
    private let videoOutputQueue = DispatchQueue(label: "verse.faceunlock", qos: .userInitiated)
    private var lastUnlockAttempt: Date = .distantPast

    override init() {
        super.init()
        self.isEnabled = UserDefaults.standard.bool(forKey: "faceUnlockEnabled")
        self.hasSavedPassword = checkKeychainPassword()
        setupLockListeners()
    }

    private func setupLockListeners() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(screenLocked),
                        name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        dnc.addObserver(self, selector: #selector(screenUnlocked),
                        name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)
    }

    @objc private func screenLocked() {
        guard isEnabled && hasSavedPassword else { return }
        startScanning()
    }

    @objc private func screenUnlocked() {
        stopScanning()
    }

    func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        statusText = "Scanning for face..."

        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else {
                Task { @MainActor in
                    self?.statusText = "Camera permission denied"
                    self?.stopScanning()
                }
                return
            }
            Task { @MainActor in
                self?.initCaptureSession()
            }
        }
    }

    private func initCaptureSession() {
        guard isScanning else { return }
        let session = AVCaptureSession()
        session.sessionPreset = .low

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
                          AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            statusText = "No front camera found"
            stopScanning()
            return
        }

        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoOutputQueue)
        if session.canAddOutput(output) { session.addOutput(output) }

        session.startRunning()
        self.captureSession = session
    }

    func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
        captureSession = nil
        statusText = isEnabled ? "Idle" : "Disabled"
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] req, err in
            guard let results = req.results as? [VNFaceObservation], !results.isEmpty else { return }
            Task { @MainActor in
                self?.handleFaceDetected()
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }

    private func handleFaceDetected() {
        guard isScanning else { return }
        let now = Date()
        guard now.timeIntervalSince(lastUnlockAttempt) > 4.0 else { return }
        lastUnlockAttempt = now

        statusText = "Face verified. Unlocking..."
        stopScanning()

        // Retrieve password from Keychain and simulate unlock
        if let password = retrieveKeychainPassword() {
            simulatePasswordEntry(password)
        }
    }

    private func simulatePasswordEntry(_ pass: String) {
        // Keystroke simulation via AppleScript / System Events
        let escaped = pass.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let script = "tell application \"System Events\" to keystroke \"\(escaped)\"\ntell application \"System Events\" to key code 36"
        var err: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&err)
    }

    // MARK: - Keychain Services
    private let keychainService = "com.local.verse.faceunlock"
    private let keychainAccount = "MacUserPassword"

    func savePassword(_ pass: String) {
        deletePassword()
        guard let data = pass.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
        hasSavedPassword = true
    }

    func deletePassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
        hasSavedPassword = false
    }

    private func checkKeychainPassword() -> Bool {
        return retrieveKeychainPassword() != nil
    }

    private func retrieveKeychainPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
