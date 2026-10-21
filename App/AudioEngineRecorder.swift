import AVFoundation
import MowaShared

/// Records from the microphone with the audio engine. The audio background mode keeps it running.
///
/// Each recording gives one stream of 16 kHz mono samples to `onStream`. The stream ends when the
/// recording stops, so the consumer can cut the last utterance.
nonisolated final class AudioEngineRecorder: AudioRecorder, @unchecked Sendable {
    // The engine is not Sendable. Only the session controller on the main actor calls this type.
    private let engine = AVAudioEngine()
    private let onStream: @Sendable (AsyncStream<[Float]>) -> Void
    private var samples: AsyncStream<[Float]>.Continuation?

    init(onStream: @escaping @Sendable (AsyncStream<[Float]>) -> Void) {
        self.onStream = onStream
    }

    func start() throws(AudioRecorderError) {
        try Result { try run() }
            .mapError { _ in AudioRecorderError.audioSessionFailed }
            .get()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        samples?.finish()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func run() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        let (stream, continuation) = AsyncStream.makeStream(of: [Float].self)
        samples = continuation
        onStream(stream)
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        let converter = SampleConverter(from: format)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            if let converted = converter.samples(from: buffer) {
                continuation.yield(converted)
            }
        }
        try engine.start()
    }
}
