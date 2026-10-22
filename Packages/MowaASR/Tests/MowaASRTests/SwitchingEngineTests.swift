import MowaCore
import Testing

@testable import MowaASR

private struct FixedEngine: TranscriptionEngine {
    let text: String

    func transcribe(_: [Float]) async throws(TranscriptionError) -> Transcript {
        Transcript(text: text)
    }
}

@Suite("Switching engine")
struct SwitchingEngineTests {
    private func makeEngine(_ choice: ModelChoice, withWhisper: Bool = true) -> SwitchingEngine {
        var engines: [ModelChoice: any TranscriptionEngine] = [.parakeet: FixedEngine(text: "p")]
        if withWhisper { engines[.whisper] = FixedEngine(text: "w") }
        return SwitchingEngine(choice: { choice }, engines: engines)
    }

    @Test func usesParakeetWhenSelected() async throws {
        #expect(try await makeEngine(.parakeet).transcribe([]).text == "p")
    }

    @Test func usesWhisperWhenSelected() async throws {
        #expect(try await makeEngine(.whisper).transcribe([]).text == "w")
    }

    @Test func failsWhenThereIsNoEngineForTheChoice() async {
        await #expect(throws: TranscriptionError.modelNotInstalled) {
            try await makeEngine(.whisper, withWhisper: false).transcribe([])
        }
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
            engines: [.whisper: FixedEngine(text: "w")],
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
