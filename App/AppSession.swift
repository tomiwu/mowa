import Foundation
import MowaShared

/// Builds the session controller with the App Group store and the microphone.
enum AppSession {
    @MainActor
    static func makeController() -> SessionController {
        SessionController(
            store: SharedStore(
                container: FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: MowaShared.appGroupIdentifier
                ),
                fallback: FileManager.default.temporaryDirectory
            ),
            notifier: DarwinNotifier(transport: SystemNotificationTransport()),
            recorder: AudioEngineRecorder(),
            sleep: { try await Task.sleep(for: $0) }
        )
    }
}
