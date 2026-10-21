import Foundation
import MowaASR
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
            recorder: AudioEngineRecorder { stream in
                Task { await SpeechCapture.run(stream) }
            },
            sleep: { try await Task.sleep(for: $0) }
        )
    }
}

/// Cuts the audio of one recording into utterances with the Silero VAD model.
nonisolated enum SpeechCapture {
    static func run(_ input: AsyncStream<[Float]>) async {
        try? await process(input)
    }

    private static func process(_ input: AsyncStream<[Float]>) async throws(SpeechPipelineError) {
        let detector = try await SileroSpeechDetector()
        // The ASR engine takes over the utterances in the next issue (T1.5).
        try await SpeechPipeline(detector: detector).run(input) { _ in }
    }
}
