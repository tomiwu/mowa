import Foundation
import MowaASR
import MowaCore
import MowaShared

/// Builds the session controller with the App Group store and the microphone.
enum AppSession {
    nonisolated static let modelChoiceStorage = ModelChoiceStorage(
        suiteName: MowaShared.appGroupIdentifier
    )

    @MainActor
    static func makeManagers() -> [ModelChoice: ModelManager] {
        [
            .parakeet: ModelManager(store: ParakeetModelStore()),
            .whisper: ModelManager(store: WhisperModelStore()),
        ]
    }

    @MainActor
    static func makeController(history: HistoryModel) -> SessionController {
        let store = makeStore()
        let notifier = DarwinNotifier(transport: SystemNotificationTransport())
        let log = PhaseLog.system()
        let relay = DictationRelay(
            engine: SwitchingEngine(
                choice: { Self.modelChoiceStorage.choice },
                makers: [
                    .parakeet: { ParakeetEngine(store: ParakeetModelStore(), log: log) },
                    .whisper: { WhisperEngine(store: WhisperModelStore(), log: log) },
                ],
                log: log
            ),
            store: store,
            notifier: notifier,
            history: { entry in await history.record(entry) }
        )
        return SessionController(
            store: store,
            notifier: notifier,
            recorder: AudioEngineRecorder(
                log: log,
                model: { Self.modelChoiceStorage.choice },
                onStream: { stream in
                    Task { await SpeechCapture.run(stream, relay: relay) }
                }
            ),
            sleep: { try await Task.sleep(for: $0) }
        )
    }

    private static func makeStore() -> SharedStore {
        SharedStore(
            container: FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: MowaShared.appGroupIdentifier
            ),
            fallback: FileManager.default.temporaryDirectory
        )
    }
}

/// Cuts the audio of one recording into utterances with the Silero VAD model and transcribes
/// each utterance on the device.
nonisolated enum SpeechCapture {
    static func run(_ input: AsyncStream<[Float]>, relay: DictationRelay) async {
        try? await process(input, relay: relay)
    }

    private static func process(
        _ input: AsyncStream<[Float]>,
        relay: DictationRelay
    ) async throws(SpeechPipelineError) {
        let detector = try await SileroSpeechDetector()
        try await SpeechPipeline(detector: detector).run(input) { await relay.handle($0) }
    }
}
