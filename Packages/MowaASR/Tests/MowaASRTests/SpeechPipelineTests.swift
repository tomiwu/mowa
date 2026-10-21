import Testing

@testable import MowaASR

private struct FakeDetector: SpeechActivityDetector {
    let failure: SpeechPipelineError?

    init(failure: SpeechPipelineError? = nil) {
        self.failure = failure
    }

    func probability(of chunk: [Float]) async throws(SpeechPipelineError) -> Float {
        if let failure { throw failure }
        return (chunk.first ?? 0) > 0.5 ? 1 : 0
    }
}

private actor Collector {
    private(set) var segments: [SpeechSegment] = []

    func add(_ segment: SpeechSegment) {
        segments.append(segment)
    }
}

private let size = SegmenterConfig.chunkSize

private func samples(_ value: Float, chunks: Int = 1) -> [Float] {
    [Float](repeating: value, count: size * chunks)
}

private func stream(_ parts: [[Float]]) -> AsyncStream<[Float]> {
    AsyncStream { continuation in
        parts.forEach { continuation.yield($0) }
        continuation.finish()
    }
}

struct SpeechPipelineTests {
    private let config = SegmenterConfig(
        startThreshold: 0.8,
        endThreshold: 0.5,
        minSilenceChunks: 2,
        prerollChunks: 0
    )

    private func run(
        _ parts: [[Float]],
        detector: FakeDetector = FakeDetector()
    ) async throws(SpeechPipelineError) -> [SpeechSegment] {
        let collector = Collector()
        let pipeline = SpeechPipeline(detector: detector, config: config)
        try await pipeline.run(stream(parts)) { await collector.add($0) }
        return await collector.segments
    }

    @Test func silenceEndsAnUtterance() async throws {
        let result = try await run([samples(1), samples(0, chunks: 2), samples(1)])
        #expect(result.map(\.samples.count) == [size * 3, size])
    }

    @Test func endOfInputCutsOpenSpeech() async throws {
        let result = try await run([samples(1)])
        #expect(result == [SpeechSegment(samples: samples(1))])
    }

    @Test func unevenInputIsRechunked() async throws {
        let half = [Float](repeating: 1, count: size / 2)
        let result = try await run([half, half])
        #expect(result == [SpeechSegment(samples: samples(1))])
    }

    @Test func partialTailIsPaddedAndChecked() async throws {
        let result = try await run([[Float](repeating: 1, count: 10)])
        #expect(result.map(\.samples.count) == [size])
    }

    @Test func emptyInputGivesNothing() async throws {
        #expect(try await run([]).isEmpty)
    }

    @Test func detectorFailureStopsThePipeline() async {
        let detector = FakeDetector(failure: .detectionFailed)
        await #expect(throws: SpeechPipelineError.detectionFailed) {
            try await run([samples(1)], detector: detector)
        }
    }
}

struct MapFailureTests {
    private struct Boom: Error {}

    @Test func returnsTheValue() async throws {
        #expect(try await mapFailure(to: .detectionFailed) { 5 } == 5)
    }

    @Test func replacesTheError() async {
        await #expect(throws: SpeechPipelineError.detectorUnavailable) {
            try await mapFailure(to: .detectorUnavailable) { throw Boom() }
        }
    }
}
