import MowaCore

/// Runs `body` and reports each error of it as `failure`.
func mapTranscriptionFailure<Value>(
    to failure: TranscriptionError,
    _ body: () async throws -> Value
) async throws(TranscriptionError) -> Value {
    do {
        return try await body()
    } catch {
        throw failure
    }
}
