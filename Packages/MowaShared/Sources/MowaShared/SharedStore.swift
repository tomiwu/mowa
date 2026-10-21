public import Foundation

/// Store for results, word list and settings in a shared directory.
///
/// In the app and in the keyboard, the directory is the App Group container.
public struct SharedStore: Sendable {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// Opens the store in a container, or fails when there is no container.
    init(container: URL?) throws(SharedStoreError) {
        guard let container else { throw .containerUnavailable }
        self.init(directory: container)
    }

    /// Opens the store in a container, or in a fallback directory when there is no container.
    public init(container: URL?, fallback: URL) {
        self.init(directory: container ?? fallback)
    }

    #if canImport(Darwin)
        /// Opens the store in the App Group container.
        public init(appGroupIdentifier: String) throws(SharedStoreError) {
            try self.init(
                container: FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: appGroupIdentifier
                )
            )
        }
    #endif

    public func writeResult(_ result: DictationResult) throws(SharedStoreError) {
        try write(result, to: "result.json")
    }

    /// Returns the last result, or `nil` when there is none.
    public func readResult() throws(SharedStoreError) -> DictationResult? {
        try read(DictationResult.self, from: "result.json")
    }

    /// Removes the last result. A missing result is not an error.
    public func clearResult() {
        try? FileManager.default.removeItem(at: url(for: "result.json"))
    }

    public func writeWordList(_ words: [String]) throws(SharedStoreError) {
        try write(words, to: "words.json")
    }

    public func saveWordList(_ list: WordList) throws(SharedStoreError) {
        try writeWordList(list.words)
    }

    public func readWordList() throws(SharedStoreError) -> [String] {
        try read([String].self, from: "words.json") ?? []
    }

    public func loadWordList() throws(SharedStoreError) -> WordList {
        WordList(words: try readWordList())
    }

    public func writeSessionStatus(_ status: SessionStatus) throws(SharedStoreError) {
        try write(status, to: "session.json")
    }

    /// Returns the session status, or `.noSession` when the app wrote none.
    public func readSessionStatus() throws(SharedStoreError) -> SessionStatus {
        try read(SessionStatus.self, from: "session.json") ?? .noSession
    }

    public func writeSettings(_ settings: SharedSettings) throws(SharedStoreError) {
        try write(settings, to: "settings.json")
    }

    public func readSettings() throws(SharedStoreError) -> SharedSettings {
        try read(SharedSettings.self, from: "settings.json") ?? .standard
    }

    public func writeKeyboardReport(_ report: KeyboardReport) throws(SharedStoreError) {
        try write(report, to: "keyboard.json")
    }

    /// Returns the keyboard report, or `nil` when the keyboard never wrote one.
    public func readKeyboardReport() throws(SharedStoreError) -> KeyboardReport? {
        try read(KeyboardReport.self, from: "keyboard.json")
    }

    public func writeInputFocus(_ focus: InputFocus) throws(SharedStoreError) {
        try write(focus, to: "focus.json")
    }

    /// Returns the focus of the keyboard, or `nil` when the keyboard never wrote one.
    public func readInputFocus() throws(SharedStoreError) -> InputFocus? {
        try read(InputFocus.self, from: "focus.json")
    }

    private func url(for name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    private func write<Value: Encodable>(
        _ value: Value,
        to name: String
    ) throws(SharedStoreError) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url(for: name), options: .atomic)
        } catch {
            throw .writeFailed
        }
    }

    private func read<Value: Decodable>(
        _ type: Value.Type,
        from name: String
    ) throws(SharedStoreError) -> Value? {
        guard FileManager.default.fileExists(atPath: url(for: name).path) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: Data(contentsOf: url(for: name)))
        } catch {
            throw .readFailed
        }
    }
}
