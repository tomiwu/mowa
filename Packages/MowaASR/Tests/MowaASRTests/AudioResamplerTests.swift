import Testing

@testable import MowaASR

struct AudioResamplerTests {
    @Test func noChannelsGiveNoSamples() {
        #expect(AudioResampler.mono16k(channels: nil, sampleRate: 48_000).isEmpty)
        #expect(AudioResampler.mono16k(channels: [], sampleRate: 48_000).isEmpty)
    }

    @Test func badRateGivesNoSamples() {
        #expect(AudioResampler.mono16k(channels: [[1, 2]], sampleRate: 0).isEmpty)
    }

    @Test func monoAtTargetRateIsUnchanged() {
        #expect(AudioResampler.mono16k(channels: [[1, 2, 3]], sampleRate: 16_000) == [1, 2, 3])
    }

    @Test func channelsAreAveraged() {
        #expect(AudioResampler.mono([[1, 3, 5], [3, 5]]) == [2, 4])
    }

    @Test func downsamplingAveragesEachWindow() {
        let samples: [Float] = [1, 2, 3, 4, 5, 6, 7]
        #expect(AudioResampler.mono16k(channels: [samples], sampleRate: 48_000) == [2, 5])
    }

    @Test func upsamplingRepeatsSamples() {
        #expect(AudioResampler.mono16k(channels: [[1, 2]], sampleRate: 8_000) == [1, 1, 2, 2])
    }

    @Test func averageUsesAtLeastOneSample() {
        #expect(AudioResampler.average([4, 8], from: 1, to: 1) == 8)
    }
}

struct ChunkBufferTests {
    @Test func keepsLessThanOneChunkPending() {
        var buffer = ChunkBuffer(chunkSize: 4)
        #expect(buffer.append([1, 2, 3]).isEmpty)
        #expect(buffer.pendingCount == 3)
        #expect(buffer.append([4, 5, 6, 7, 8, 9]) == [[1, 2, 3, 4], [5, 6, 7, 8]])
        #expect(buffer.pendingCount == 1)
    }

    @Test func longInputLeavesOnlyTheRemainder() {
        var buffer = ChunkBuffer(chunkSize: 4)
        let chunks = buffer.append([Float](repeating: 1, count: 4 * 1000 + 2))
        #expect(chunks.count == 1000)
        #expect(buffer.pendingCount == 2)
    }

    @Test func flushPadsAndEmptiesTheBuffer() {
        var buffer = ChunkBuffer(chunkSize: 4)
        #expect(buffer.flush() == nil)
        _ = buffer.append([1, 2])
        #expect(buffer.flush() == [1, 2, 0, 0])
        #expect(buffer.pendingCount == 0)
    }
}
