/// Makes a stream of progress values from an operation that reports them.
///
/// The stream ends when the operation ends. It throws the error of the operation. When the
/// consumer stops, the operation is cancelled.
func progressStream(
    _ operation:
        @escaping @Sendable (_ report: @escaping @Sendable (Double) -> Void) async throws
        -> Void
) -> AsyncThrowingStream<Double, any Error> {
    let (stream, continuation) = AsyncThrowingStream<Double, any Error>.makeStream()
    let task = Task {
        do {
            try await operation { continuation.yield($0) }
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }
    continuation.onTermination = { _ in task.cancel() }
    return stream
}
