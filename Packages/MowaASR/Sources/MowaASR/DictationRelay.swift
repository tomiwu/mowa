public import Foundation
public import MowaCore
public import MowaShared

/// Transcribes each utterance, corrects the names with the word list
/// and sends the text to the keyboard through the App Group.
public struct DictationRelay: Sendable {
    private let engine: any TranscriptionEngine
    private let store: SharedStore
    private let notifier: DarwinNotifier
    private let makeID: @Sendable () -> UUID
    private let now: @Sendable () -> Date
    private let history: @Sendable (HistoryEntry) async -> Void

    public init(
        engine: any TranscriptionEngine,
        store: SharedStore,
        notifier: DarwinNotifier,
        makeID: @escaping @Sendable () -> UUID = { UUID() },
        now: @escaping @Sendable () -> Date = { Date() },
        history: @escaping @Sendable (HistoryEntry) async -> Void = { _ in }
    ) {
        self.engine = engine
        self.store = store
        self.notifier = notifier
        self.makeID = makeID
        self.now = now
        self.history = history
    }

    /// Transcribes the utterance. The audio stays on the device. A failed or empty
    /// transcription sends nothing.
    public func handle(_ segment: SpeechSegment) async {
        guard let transcript = try? await engine.transcribe(segment.samples) else { return }
        await publish(transcript, duration: segment.duration)
    }

    private func publish(_ transcript: Transcript, duration: Double) async {
        guard !transcript.text.isEmpty else { return }
        let words = (try? store.readWordList()) ?? []
        let text = WordCorrector(words: words).correct(transcript.text)
        let result = DictationResult(
            id: makeID(),
            text: text,
            languageCode: transcript.languageCode,
            createdAt: now()
        )
        await history(
            HistoryEntry(
                id: result.id,
                date: result.createdAt,
                text: result.text,
                languageCode: result.languageCode,
                duration: duration
            )
        )
        guard (try? store.writeResult(result)) != nil else { return }
        notifier.postResultReady()
    }
}
