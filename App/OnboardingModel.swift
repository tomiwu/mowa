import AVFoundation
import MowaShared
import Observation
import UIKit

/// Detects the setup state for the first-run flow and asks for the microphone.
@MainActor
@Observable
final class OnboardingModel {
    private(set) var state = OnboardingState(
        keyboardAdded: false,
        fullAccess: false,
        microphone: .undetermined
    )
    private let store: SharedStore?

    private static let permissions: [AVAudioApplication.recordPermission: MicrophonePermission] =
        [.granted: .granted, .denied: .denied]

    init(store: SharedStore?) {
        self.store = store
    }

    func refresh() {
        let report = (try? store?.readKeyboardReport()) ?? nil
        state = OnboardingState(
            keyboardAdded: report != nil,
            fullAccess: report?.hasFullAccess == true,
            microphone: Self.permissions[AVAudioApplication.shared.recordPermission]
                ?? .undetermined
        )
    }

    func requestMicrophone() async {
        _ = await AVAudioApplication.requestRecordPermission()
        refresh()
    }

    func openSettings() {
        _ = URL(string: UIApplication.openSettingsURLString).map {
            UIApplication.shared.open($0)
        }
    }
}
