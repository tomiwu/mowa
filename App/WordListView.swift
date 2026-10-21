import MowaShared
import SwiftUI
import UniformTypeIdentifiers

/// Shows the word list with add, edit, delete, import and export.
struct WordListView: View {
    let model: WordListModel
    @State private var draft = ""
    @State private var editing: Int?
    @State private var importing = false

    var body: some View {
        List {
            HStack {
                TextField("Word", text: $draft).onSubmit(commit)
                Button(editing == nil ? "Add" : "Save", action: commit)
            }
            ForEach(Array(model.list.words.enumerated()), id: \.offset) { index, word in
                Button(word) { begin(editing: index, word: word) }
            }
            .onDelete { model.delete(at: $0) }
        }
        .toolbar {
            Button("Import") { importing = true }
            ShareLink(item: model.list.exportedText)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) {
            _ = try? $0.get().readText().map(model.importText)
        }
    }

    private func begin(editing index: Int, word: String) {
        editing = index
        draft = word
    }

    private func commit() {
        model.submit(draft, editing: editing)
        editing = nil
        draft = ""
    }
}

extension URL {
    fileprivate func readText() -> String? {
        _ = startAccessingSecurityScopedResource()
        defer { stopAccessingSecurityScopedResource() }
        return try? String(contentsOf: self, encoding: .utf8)
    }
}
