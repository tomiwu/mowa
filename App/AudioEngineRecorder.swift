import AVFoundation
import MowaShared

/// Records from the microphone with the audio engine. The audio background mode keeps it running.
nonisolated final class AudioEngineRecorder: AudioRecorder, @unchecked Sendable {
    // The engine is not Sendable. Only the session controller on the main actor calls this type.
    private let engine = AVAudioEngine()

    func start() throws(AudioRecorderError) {
        do {
            try run()
        } catch {
            throw .audioSessionFailed
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func run() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        let input = engine.inputNode
        input.installTap(onBus: 0, bufferSize: 4096, format: input.outputFormat(forBus: 0)) {
            _,
            _ in
        }
        try engine.start()
    }
}
