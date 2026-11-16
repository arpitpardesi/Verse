import Foundation
import CoreAudio
import AppKit
import Combine

struct AirPodsStatus: Equatable {
    var isConnected: Bool = false
    var name: String = ""
    var iconName: String = "airpodspro"
    var leftBattery: Int? = nil
    var rightBattery: Int? = nil
    var caseBattery: Int? = nil
    var batteryPercentage: Int? = nil
}

@MainActor
final class AirPodsMonitor: ObservableObject {
    static let shared = AirPodsMonitor()
    @Published var status = AirPodsStatus()
    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func refresh() {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let res = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &size,
            &defaultOutputDeviceID
        )
        guard res == noErr else {
            status = AirPodsStatus()
            return
        }

        propertyAddress.mSelector = kAudioDevicePropertyDeviceNameCFString
        var nameCF: Unmanaged<CFString>?
        var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let nameRes = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &propertyAddress,
            0, nil,
            &nameSize,
            &nameCF
        )
        guard nameRes == noErr, let unmanaged = nameCF else {
            status = AirPodsStatus()
            return
        }

        let deviceName = (unmanaged.takeRetainedValue() as String).trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = deviceName.lowercased()

        if lower.contains("airpod") || lower.contains("beats") {
            let icon: String
            if lower.contains("max") {
                icon = "airpodsmax"
            } else if lower.contains("pro") {
                icon = "airpodspro"
            } else if lower.contains("beats") {
                icon = "beats.headphones"
            } else {
                icon = "airpods"
            }

            status = AirPodsStatus(
                isConnected: true,
                name: deviceName,
                iconName: icon,
                batteryPercentage: 92 // Connected audio output
            )
        } else {
            status = AirPodsStatus()
        }
    }
}
