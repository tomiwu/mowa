import MowaCore
import Testing

@testable import MowaASR

private struct FixedEngine: TranscriptionEngine {
    let text: String

    func transcribe(_ samples: [Float]) async throws(TranscriptionError) -> Transcript {
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
