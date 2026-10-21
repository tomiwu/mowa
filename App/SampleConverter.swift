import AVFoundation

/// Converts microphone buffers to 16 kHz mono samples, the format of the VAD and the ASR models.
nonisolated final class SampleConverter: @unchecked Sendable {
    // The converter is not Sendable. Only the audio tap calls this type, one buffer at a time.
    private let output = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)
    private let converter: AVAudioConverter?

    init(from input: AVAudioFormat) {
        converter = output.flatMap { AVAudioConverter(from: input, to: $0) }
    }

    /// Returns nil when the buffer cannot be converted.
    func samples(from buffer: AVAudioPCMBuffer) -> [Float]? {
        output.flatMap { converted(buffer, to: $0) }.flatMap(Self.floats)
    }

    private func converted(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat)
        -> AVAudioPCMBuffer?
    {
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        let result = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity)
        let input = Input(buffer)
        var error: NSError?
        converter?.convert(to: result ?? buffer, error: &error) { _, status in
            input.next(status)
        }
        return result
    }

    /// Hands the input buffer to the converter once. The converter calls it on one thread.
    private final class Input: @unchecked Sendable {
        private let buffer: AVAudioPCMBuffer
        private var supplied = false

        init(_ buffer: AVAudioPCMBuffer) {
            self.buffer = buffer
        }

        func next(_ status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
            status.pointee = supplied ? .noDataNow : .haveData
            let result = supplied ? nil : buffer
            supplied = true
            return result
        }
    }

    private static func floats(from buffer: AVAudioPCMBuffer) -> [Float]? {
        buffer.floatChannelData.map {
            Array(UnsafeBufferPointer(start: $0[0], count: Int(buffer.frameLength)))
        }
    }
}
