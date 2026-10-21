import Foundation
import Testing

@testable import MowaCore

@MainActor
struct HistoryTests {
    private let store = InMemoryHistoryStore()
    private var copied = CopyLog()

    private func entry(_ text: String, at seconds: Double = 0) -> HistoryEntry {
        HistoryEntry(
            id: UUID(),
            date: Date(timeIntervalSince1970: seconds),
            text: text,
            languageCode: "pl",
            duration: 2.5
        )
    }

    private func model(secure: Bool = false) -> HistoryModel {
        HistoryModel(store: store, isSecureField: { secure }, copy: { [copied] in copied.add($0) })
    }

    @Test func recordedEntryKeepsAllFields() {
        let model = model()
        let item = entry("Cześć", at: 7)
        model.record(item)
        #expect(model.entries == [item])
        #expect(model.entries.first?.languageCode == "pl")
        #expect(model.entries.first?.duration == 2.5)
    }

    @Test func newestEntryIsFirst() {
        let model = model()
        model.record(entry("old", at: 1))
        model.record(entry("new", at: 2))
        #expect(model.entries.map(\.text) == ["new", "old"])
    }

    @Test func secureFieldTextIsNotRecorded() {
        let model = model(secure: true)
        model.record(entry("secret"))
        #expect(model.entries.isEmpty)
        #expect(store.all().isEmpty)
    }

    @Test func emptyTextIsNotRecorded() {
        let model = model()
        model.record(entry(""))
        #expect(model.entries.isEmpty)
    }

    @Test func deleteRemovesOneEntry() {
        let model = model()
        let keep = entry("keep", at: 1)
        let drop = entry("drop", at: 2)
        model.record(keep)
        model.record(drop)
        model.delete(drop.id)
        #expect(model.entries == [keep])
    }

    @Test func deleteAllRemovesEverything() {
        let model = model()
        model.record(entry("a"))
        model.record(entry("b"))
        model.deleteAll()
        #expect(model.entries.isEmpty)
        #expect(store.all().isEmpty)
    }

    @Test func copySendsTheText() {
        let model = model()
        model.copy(entry("hello"))
        #expect(copied.items == ["hello"])
    }

    @Test func refreshReadsTheStore() {
        let model = model()
        store.add(entry("direct"))
        model.refresh()
        #expect(model.entries.map(\.text) == ["direct"])
    }
}

private final class CopyLog: @unchecked Sendable {  // Test only: one thread uses it.
    private(set) var items: [String] = []

    func add(_ text: String) {
        items.append(text)
    }
}
