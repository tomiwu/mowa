import AVFoundation
import MowaASR

/// Reads microphone buffers as 16 kHz mono samples. `AudioResampler` in MowaASR does the math.
nonisolated enum SampleConverter {
    static func samples(from buffer: AVAudioPCMBuffer) -> [Float] {
        AudioResampler.mono16k(
            channels: buffer.floatChannelData.map { data in
                (0..<Int(buffer.format.channelCount)).map { channel in
                    Array(UnsafeBufferPointer(start: data[channel], count: Int(buffer.frameLength)))
                }
            },
            sampleRate: buffer.format.sampleRate
        )
    }
}
