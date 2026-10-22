public import Foundation
public import MowaCore
public import MowaShared

/// Transcribes each utterance, corrects the names with the word list,
/// cleans up the text when the user turns it on
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
        do {
            let transcript = try await engine.transcribe(segment.samples)
            clearLowMemory()
            await publish(transcript, duration: segment.duration)
        } catch {
            reportLowMemory(error)
        }
    }

    /// Shows "not enough memory" in the session status when the model load is refused.
    private func reportLowMemory(_ error: TranscriptionError) {
        guard error == .notEnoughMemory else { return }
        setStatus(.lowMemory)
    }

    /// Shows the recording status again after a transcription works.
    private func clearLowMemory() {
        guard (try? store.readSessionStatus()) == .lowMemory else { return }
        setStatus(.recording)
    }

    private func setStatus(_ status: SessionStatus) {
        try? store.writeSessionStatus(status)
        notifier.postSessionChanged()
    }

    /// Corrects the names. Runs the clean-up on the device only when the setting is ON.
    private func processed(_ text: String) -> String {
        let words = (try? store.readWordList()) ?? []
        let corrected = WordCorrector(words: words).correct(text)
        return store.isCleanUpEnabled ? TextCleaner().clean(corrected) : corrected
    }

    private func publish(_ transcript: Transcript, duration: Double) async {
        let text = processed(transcript.text)
        guard !text.isEmpty else { return }
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
