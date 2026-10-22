import Testing

@testable import MowaASR

struct SpeechSegmenterTests {
    private let config = SegmenterConfig(
        startThreshold: 0.8,
        endThreshold: 0.5,
        minSilenceChunks: 2,
        prerollChunks: 1
    )

    private func chunk(_ value: Float) -> [Float] {
        [value, value]
    }

    @Test func silenceProducesNoSegment() {
        var segmenter = SpeechSegmenter(config: config)
        #expect(segmenter.push(chunk(0), probability: 0.1) == nil)
        #expect(segmenter.finish() == nil)
    }

    @Test func segmentEndsAfterEnoughSilence() {
        var segmenter = SpeechSegmenter(config: config)
        #expect(segmenter.push(chunk(1), probability: 0.9) == nil)
        #expect(segmenter.push(chunk(2), probability: 0.2) == nil)
        let segment = segmenter.push(chunk(3), probability: 0.2)
        #expect(segment == SpeechSegment(samples: [1, 1, 2, 2, 3, 3]))
    }

    @Test func speechResetsTheSilenceCount() {
        var segmenter = SpeechSegmenter(config: config)
        _ = segmenter.push(chunk(1), probability: 0.9)
        _ = segmenter.push(chunk(2), probability: 0.2)
        #expect(segmenter.push(chunk(3), probability: 0.6) == nil)
        #expect(segmenter.push(chunk(4), probability: 0.2) == nil)
    }

    @Test func prerollStaysInTheSegment() {
        var segmenter = SpeechSegmenter(config: config)
        _ = segmenter.push(chunk(7), probability: 0.1)
        _ = segmenter.push(chunk(8), probability: 0.1)
        _ = segmenter.push(chunk(1), probability: 0.9)
        #expect(segmenter.finish() == SpeechSegment(samples: [8, 8, 1, 1]))
    }

    @Test func finishCutsOpenSpeech() {
        var segmenter = SpeechSegmenter(config: config)
        _ = segmenter.push(chunk(1), probability: 0.9)
        #expect(segmenter.finish() == SpeechSegment(samples: [1, 1]))
        #expect(segmenter.finish() == nil)
    }

    @Test func nextUtteranceStartsClean() {
        var segmenter = SpeechSegmenter(config: config)
        _ = segmenter.push(chunk(1), probability: 0.9)
        _ = segmenter.finish()
        _ = segmenter.push(chunk(5), probability: 0.9)
        #expect(segmenter.finish() == SpeechSegment(samples: [5, 5]))
    }

    @Test func longSpeechIsCutAtTheLimit() {
        let limited = SegmenterConfig(
            startThreshold: 0.8,
            endThreshold: 0.5,
            minSilenceChunks: 2,
            prerollChunks: 1,
            maxChunks: 3
        )
        var segmenter = SpeechSegmenter(config: limited)
        #expect(segmenter.push(chunk(1), probability: 0.9) == nil)
        #expect(segmenter.push(chunk(2), probability: 0.9) == nil)
        #expect(
            segmenter.push(chunk(3), probability: 0.9)
                == SpeechSegment(samples: [1, 1, 2, 2, 3, 3])
        )
        #expect(segmenter.finish() == nil)
    }

    @Test func prerollCountsForTheLimit() {
        let limited = SegmenterConfig(
            startThreshold: 0.8,
            endThreshold: 0.5,
            minSilenceChunks: 2,
            prerollChunks: 1,
            maxChunks: 2
        )
        var segmenter = SpeechSegmenter(config: limited)
        _ = segmenter.push(chunk(7), probability: 0.1)
        _ = segmenter.push(chunk(1), probability: 0.9)
        #expect(
            segmenter.push(chunk(2), probability: 0.9)
                == SpeechSegment(samples: [7, 7, 1, 1, 2, 2])
        )
    }

    @Test func thirtySecondsOfSpeechGiveSegmentsOfFifteenSecondsOrLess() {
        var segmenter = SpeechSegmenter()
        let size = SegmenterConfig.chunkSize
        let total = 30 * SegmenterConfig.sampleRate / size
        var segments: [SpeechSegment] = []
        for _ in 0..<total {
            segments += [segmenter.push([Float](repeating: 1, count: size), probability: 1)]
                .compactMap { $0 }
        }
        segments += [segmenter.finish()].compactMap { $0 }
        #expect(segments.count >= 2)
        let limit = SegmenterConfig.maxUtteranceSeconds * SegmenterConfig.sampleRate
        #expect(segments.allSatisfy { $0.samples.count <= limit })
        #expect(segments.reduce(0) { $0 + $1.samples.count } == total * size)
    }
}
