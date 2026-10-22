import Testing

@testable import MowaCore

private final class Lines: @unchecked Sendable {
    // Tests call it from one task at a time.
    var values: [String] = []
}

private struct LoadError: Error {}

@Suite("Phase log")
struct PhaseLogTests {
    private func makeLog(_ lines: Lines, bytes: UInt64 = 1_000) -> PhaseLog {
        PhaseLog(write: { lines.values.append($0) }, availableBytes: { bytes })
    }

    @Test func messageHasPhaseModelAndBytes() {
        let text = PhaseLog.message(phase: .modelLoadStart, model: .parakeet, availableBytes: 42)
        #expect(text == "model-load-start model=parakeet available-bytes=42")
    }

    @Test func everyPhaseHasOwnName() {
        let names = Set(PhaseLog.Phase.allCases.map(\.rawValue))
        #expect(names.count == PhaseLog.Phase.allCases.count)
    }

    @Test func recordWritesOneLineWithTheFreeMemory() {
        let lines = Lines()
        makeLog(lines, bytes: 7).record(.recordStart, model: .whisper)
        #expect(lines.values == ["record-start model=whisper available-bytes=7"])
    }

    @Test func aroundWritesStartThenEnd() async throws {
        let lines = Lines()
        let value = try await makeLog(lines).around(
            .transcriptionStart,
            .transcriptionEnd,
            model: .parakeet
        ) {
            5
        }
        #expect(value == 5)
        #expect(lines.values.count == 2)
        #expect(lines.values[0].hasPrefix("transcription-start"))
        #expect(lines.values[1].hasPrefix("transcription-end"))
    }

    @Test func aroundWritesNoEndLineWhenTheOperationFails() async {
        let lines = Lines()
        await #expect(throws: LoadError.self) {
            try await makeLog(lines).around(.modelLoadStart, .modelLoadEnd, model: .parakeet) {
                throw LoadError()
            }
        }
        #expect(lines.values.count == 1)
        #expect(lines.values[0].hasPrefix("model-load-start"))
    }

    @Test func silentLogDoesNothing() {
        PhaseLog.silent.record(.recordStop, model: .parakeet)
    }
}
