/// Connects the audio from the recorder to the VAD and the segmenter.
///
/// When the input stream ends (the user released the mic), the pipeline cuts the open utterance.
public actor SpeechPipeline {
    private let detector: any SpeechActivityDetector
    private var buffer = ChunkBuffer(chunkSize: SegmenterConfig.chunkSize)
    private var segmenter: SpeechSegmenter

    public init(
        detector: any SpeechActivityDetector,
        config: SegmenterConfig = .standard
    ) {
        self.detector = detector
        segmenter = SpeechSegmenter(config: config)
    }

    /// Reads the input until it ends and calls `onSegment` for each utterance.
    public func run(
        _ input: AsyncStream<[Float]>,
        onSegment: @Sendable (SpeechSegment) async -> Void
    ) async throws(SpeechPipelineError) {
        for await samples in input {
            for segment in try await feed(samples) {
                await onSegment(segment)
            }
        }
        for segment in try await finish() {
            await onSegment(segment)
        }
    }

    func feed(_ samples: [Float]) async throws(SpeechPipelineError) -> [SpeechSegment] {
        var segments: [SpeechSegment] = []
        for chunk in buffer.append(samples) {
            segments += try await process(chunk)
        }
        return segments
    }

    func finish() async throws(SpeechPipelineError) -> [SpeechSegment] {
        var segments: [SpeechSegment] = []
        for chunk in [buffer.flush()].compactMap({ $0 }) {
            segments += try await process(chunk)
        }
        return segments + [segmenter.finish()].compactMap { $0 }
    }

    private func process(_ chunk: [Float]) async throws(SpeechPipelineError) -> [SpeechSegment] {
        let probability = try await detector.probability(of: chunk)
        return [segmenter.push(chunk, probability: probability)].compactMap { $0 }
    }
}
