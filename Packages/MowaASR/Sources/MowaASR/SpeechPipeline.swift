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
            await deliver(try await feed(samples), to: onSegment)
        }
        await deliver(try await finish(), to: onSegment)
    }

    private func deliver(
        _ segments: [SpeechSegment],
        to onSegment: @Sendable (SpeechSegment) async -> Void
    ) async {
        for segment in segments {
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
        if let tail = buffer.flush() {
            segments += try await process(tail)
        }
        if let last = segmenter.finish() {
            segments.append(last)
        }
        return segments
    }

    private func process(_ chunk: [Float]) async throws(SpeechPipelineError) -> [SpeechSegment] {
        let probability = try await detector.probability(of: chunk)
        return [segmenter.push(chunk, probability: probability)].compactMap { $0 }
    }
}
