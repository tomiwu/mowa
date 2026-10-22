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
