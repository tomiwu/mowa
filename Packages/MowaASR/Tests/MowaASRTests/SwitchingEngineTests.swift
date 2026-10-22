import MowaCore
import Synchronization
import Testing

@testable import MowaASR

private final class Journal: Sendable {
    private let store = Mutex<[String]>([])

    var events: [String] { store.withLock { $0 } }

    func add(_ event: String) { store.withLock { $0.append(event) } }
}

private struct FixedEngine: ReleasableEngine {
    let name: String
    let journal: Journal

    func transcribe(_: [Float]) async throws(TranscriptionError) -> Transcript {
        journal.add("transcribe \(name)")
        return Transcript(text: name)
    }

    func release() async {
        journal.add("release \(name)")
    }
}

private final class Choice: @unchecked Sendable {
    // The tests change it between the calls.
    var value: ModelChoice

    init(_ value: ModelChoice) { self.value = value }
}

private func makers(_ journal: Journal, whisper: Bool = true)
    -> [ModelChoice: @Sendable () -> any ReleasableEngine]
{
    var result: [ModelChoice: @Sendable () -> any ReleasableEngine] = [
        .parakeet: {
            journal.add("make parakeet")
            return FixedEngine(name: "p", journal: journal)
        }
    ]
    if whisper {
        result[.whisper] = {
            journal.add("make whisper")
            return FixedEngine(name: "w", journal: journal)
        }
    }
    return result
}

@Suite("Switching engine")
struct SwitchingEngineTests {
    @Test func usesParakeetWhenSelected() async throws {
        let engine = SwitchingEngine(choice: { .parakeet }, makers: makers(Journal()))
        #expect(try await engine.transcribe([]).text == "p")
    }

    @Test func usesWhisperWhenSelected() async throws {
        let engine = SwitchingEngine(choice: { .whisper }, makers: makers(Journal()))
        #expect(try await engine.transcribe([]).text == "w")
    }

    @Test func failsWhenThereIsNoEngineForTheChoice() async {
        let engine = SwitchingEngine(
            choice: { .whisper },
            makers: makers(Journal(), whisper: false)
        )
        await #expect(throws: TranscriptionError.modelNotInstalled) {
            try await engine.transcribe([])
        }
    }

    @Test func doesNotCreateTheWhisperEngineForParakeet() async throws {
        let journal = Journal()
        let engine = SwitchingEngine(choice: { .parakeet }, makers: makers(journal))
        _ = try await engine.transcribe([])
        _ = try await engine.transcribe([])
        let events = journal.events
        #expect(!events.contains("make whisper"))
        #expect(events.filter { $0 == "transcribe p" }.count == 2)
    }

    @Test func releasesTheOldEngineBeforeTheNewEngineWorks() async throws {
        let journal = Journal()
        let choice = Choice(.parakeet)
        let engine = SwitchingEngine(choice: { choice.value }, makers: makers(journal))
        _ = try await engine.transcribe([])
        choice.value = .whisper
        _ = try await engine.transcribe([])
        let events = journal.events.filter { !$0.hasPrefix("make") }
        #expect(events == ["transcribe p", "release p", "transcribe w"])
    }

    @Test func keepsTheOldEngineWhenTheNewChoiceHasNoMaker() async throws {
        let journal = Journal()
        let choice = Choice(.parakeet)
        let engine = SwitchingEngine(
            choice: { choice.value },
            makers: makers(journal, whisper: false)
        )
        _ = try await engine.transcribe([])
        choice.value = .whisper
        await #expect(throws: TranscriptionError.modelNotInstalled) {
            try await engine.transcribe([])
        }
        #expect(!journal.events.contains("release p"))
    }
}

@Suite("Switching engine log")
struct SwitchingEngineLogTests {
    private final class Lines: @unchecked Sendable {
        // The test reads it after the engine call ends.
        var values: [String] = []
    }

    @Test func logsTranscriptionStartAndEndWithTheModel() async throws {
        let lines = Lines()
        let engine = SwitchingEngine(
            choice: { .whisper },
            makers: makers(Journal()),
            log: PhaseLog(write: { lines.values.append($0) }, availableBytes: { 9 })
        )
        _ = try await engine.transcribe([])
        #expect(
            lines.values == [
                "transcription-start model=whisper available-bytes=9",
                "transcription-end model=whisper available-bytes=9",
            ]
        )
    }
}
