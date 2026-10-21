public import Foundation

/// One dictation result in the local history. It holds no audio.
public struct HistoryEntry: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let date: Date
    public let text: String
    public let languageCode: String
    /// Length of the spoken audio in seconds.
    public let duration: Double

    public init(id: UUID, date: Date, text: String, languageCode: String, duration: Double) {
        self.id = id
        self.date = date
        self.text = text
        self.languageCode = languageCode
        self.duration = duration
    }
}

/// Keeps the history entries. SwiftData implements it in the app.
@MainActor
public protocol HistoryStore {
    /// Returns all entries, newest first.
    func all() -> [HistoryEntry]
    func add(_ entry: HistoryEntry)
    func delete(_ id: UUID)
    func deleteAll()
}

/// A history store that keeps the entries in memory.
@MainActor
public final class InMemoryHistoryStore: HistoryStore {
    private var entries: [HistoryEntry] = []

    public init() {}

    public func all() -> [HistoryEntry] {
        entries.sorted { $0.date > $1.date }
    }

    public func add(_ entry: HistoryEntry) {
        entries.append(entry)
    }

    public func delete(_ id: UUID) {
        entries.removeAll { $0.id == id }
    }

    public func deleteAll() {
        entries.removeAll()
    }
}
