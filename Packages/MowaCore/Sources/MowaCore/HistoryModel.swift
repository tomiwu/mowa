public import Foundation
public import Observation

/// State of the history screen. It records results, except text from secure text fields.
@MainActor
@Observable
public final class HistoryModel {
    public private(set) var entries: [HistoryEntry] = []
    @ObservationIgnored private let store: any HistoryStore
    @ObservationIgnored private let isSecureField: @MainActor () -> Bool
    @ObservationIgnored private let copyText: @MainActor (String) -> Void

    public init(
        store: any HistoryStore,
        isSecureField: @escaping @MainActor () -> Bool,
        copy: @escaping @MainActor (String) -> Void
    ) {
        self.store = store
        self.isSecureField = isSecureField
        copyText = copy
        refresh()
    }

    public func refresh() {
        entries = store.all()
    }

    /// Adds the entry. Empty text and text for a secure text field are dropped.
    public func record(_ entry: HistoryEntry) {
        guard !entry.text.isEmpty, !isSecureField() else { return }
        store.add(entry)
        refresh()
    }

    public func delete(_ id: UUID) {
        store.delete(id)
        refresh()
    }

    public func deleteAll() {
        store.deleteAll()
        refresh()
    }

    public func copy(_ entry: HistoryEntry) {
        copyText(entry.text)
    }
}
