import MowaCore
import SwiftUI

/// Shows the history with copy, delete one item and delete all items.
struct HistoryView: View {
    let model: HistoryModel

    var body: some View {
        List {
            ForEach(model.entries) { entry in
                HistoryRow(entry: entry)
                    .swipeActions {
                        Button("Delete", role: .destructive) { model.delete(entry.id) }
                    }
                    .contextMenu { Button("Copy") { model.copy(entry) } }
            }
        }
        .toolbar {
            Button("Delete all", role: .destructive, action: model.deleteAll)
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.text)
            Text(caption).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var caption: String {
        let date = entry.date.formatted(date: .abbreviated, time: .shortened)
        let seconds = entry.duration.formatted(.number.precision(.fractionLength(1)))
        return "\(date) · \(entry.languageCode) · \(seconds) s"
    }
}
