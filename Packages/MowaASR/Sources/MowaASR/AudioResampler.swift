/// Converts microphone samples to 16 kHz mono, the format of the VAD and the ASR models.
///
/// It has no platform code, so `swift test` measures it on Linux. Each output sample is the
/// average of the input samples in its time window (a simple low-pass filter for downsampling).
public enum AudioResampler {
    public static let targetRate = 16_000.0

    /// Mixes the channels to mono and resamples to 16 kHz. No channels or a bad rate give [].
    public static func mono16k(channels: [[Float]]?, sampleRate: Double) -> [Float] {
        resample(mono(channels ?? []), from: sampleRate)
    }

    static func mono(_ channels: [[Float]]) -> [Float] {
        let length = channels.map(\.count).min() ?? 0
        let scale = 1 / Float(max(channels.count, 1))
        return (0..<length).map { index in
            channels.reduce(0) { $0 + $1[index] } * scale
        }
    }

    static func resample(_ samples: [Float], from rate: Double) -> [Float] {
        let step = rate / targetRate
        let count = step > 0 ? Int(Double(samples.count) / step) : 0
        return (0..<count).map { index in
            average(samples, from: Int(Double(index) * step), to: Int(Double(index + 1) * step))
        }
    }

    /// The mean of `samples[start..<end]`. The window has at least one sample.
    static func average(_ samples: [Float], from start: Int, to end: Int) -> Float {
        let window = samples[start..<min(max(end, start + 1), samples.count)]
        return window.reduce(0, +) / Float(window.count)
    }
}
