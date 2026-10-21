import Foundation
import MowaCore
import SwiftData

/// The stored form of a history entry. It holds no audio.
@Model
final class HistoryRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var text: String
    var languageCode: String
    var duration: Double

    init(_ entry: HistoryEntry) {
        id = entry.id
        date = entry.date
        text = entry.text
        languageCode = entry.languageCode
        duration = entry.duration
    }

    var entry: HistoryEntry {
        HistoryEntry(
            id: id,
            date: date,
            text: text,
            languageCode: languageCode,
            duration: duration
        )
    }
}

/// Keeps the history in a local SwiftData database.
@MainActor
struct SwiftDataHistoryStore: HistoryStore {
    private let container: ModelContainer

    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    /// Opens the database. When it fails, the history stays in memory.
    static func make() -> any HistoryStore {
        (try? ModelContainer(for: HistoryRecord.self)).map(Self.init)
            ?? InMemoryHistoryStore()
    }

    func all() -> [HistoryEntry] {
        let sort = SortDescriptor(\HistoryRecord.date, order: .reverse)
        let records = try? context.fetch(FetchDescriptor<HistoryRecord>(sortBy: [sort]))
        return (records ?? []).map(\.entry)
    }

    func add(_ entry: HistoryEntry) {
        context.insert(HistoryRecord(entry))
        try? context.save()
    }

    func delete(_ id: UUID) {
        try? context.delete(model: HistoryRecord.self, where: #Predicate { $0.id == id })
        try? context.save()
    }

    func deleteAll() {
        try? context.delete(model: HistoryRecord.self)
        try? context.save()
    }
}
