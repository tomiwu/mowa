import AVFoundation
import MowaCore
import MowaShared

/// Records from the microphone with the audio engine. The audio background mode keeps it running.
///
/// Each recording gives one stream of 16 kHz mono samples to `onStream`. The stream ends when the
/// recording stops, so the consumer can cut the last utterance.
nonisolated final class AudioEngineRecorder: AudioRecorder, @unchecked Sendable {
    // The engine is not Sendable. Only the session controller on the main actor calls this type.
    private let engine = AVAudioEngine()
    private let onStream: @Sendable (AsyncStream<[Float]>) -> Void
    private let log: PhaseLog
    private let model: @Sendable () -> ModelChoice
    private var samples: AsyncStream<[Float]>.Continuation?

    init(
        log: PhaseLog,
        model: @escaping @Sendable () -> ModelChoice,
        onStream: @escaping @Sendable (AsyncStream<[Float]>) -> Void
    ) {
        self.log = log
        self.model = model
        self.onStream = onStream
    }

    func start() throws(AudioRecorderError) {
        log.record(.recordStart, model: model())
        try Result { try run() }
            .mapError { _ in AudioRecorderError.audioSessionFailed }
            .get()
    }

    func stop() {
        log.record(.recordStop, model: model())
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
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            continuation.yield(SampleConverter.samples(from: buffer))
        }
        try engine.start()
    }
}
