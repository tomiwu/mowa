public import Foundation
public import MowaCore
public import MowaShared

/// Transcribes each utterance and sends the text to the keyboard through the App Group.
public struct DictationRelay: Sendable {
    private let engine: any TranscriptionEngine
    private let store: SharedStore
    private let notifier: DarwinNotifier
    private let makeID: @Sendable () -> UUID
    private let now: @Sendable () -> Date

    public init(
        engine: any TranscriptionEngine,
        store: SharedStore,
        notifier: DarwinNotifier,
        makeID: @escaping @Sendable () -> UUID = { UUID() },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.engine = engine
        self.store = store
        self.notifier = notifier
        self.makeID = makeID
        self.now = now
    }

    /// Transcribes the utterance. The audio stays on the device. A failed or empty
    /// transcription sends nothing.
    public func handle(_ segment: SpeechSegment) async {
        guard let transcript = try? await engine.transcribe(segment.samples) else { return }
        publish(transcript)
    }

    private func publish(_ transcript: Transcript) {
        guard !transcript.text.isEmpty else { return }
        let result = DictationResult(
            id: makeID(),
            text: transcript.text,
            languageCode: transcript.languageCode,
            createdAt: now()
        )
        guard (try? store.writeResult(result)) != nil else { return }
        notifier.postResultReady()
    }
}
