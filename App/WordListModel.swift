import MowaShared
import Observation

/// Holds the word list for the screen and saves each change to the shared store.
@MainActor
@Observable
final class WordListModel {
    private(set) var list: WordList
    private let store: SharedStore?

    init(store: SharedStore?) {
        self.store = store
        list = (try? store?.loadWordList()) ?? WordList()
    }

    func add(_ word: String) -> WordList.Outcome {
        let outcome = list.add(word)
        save()
        return outcome
    }

    func edit(at index: Int, to word: String) -> WordList.Outcome {
        let outcome = list.edit(at: index, to: word)
        save()
        return outcome
    }

    func delete(at offsets: IndexSet) {
        list.delete(at: offsets)
        save()
    }

    func importText(_ text: String) {
        list.importText(text)
        save()
    }

    private func save() {
        try? store?.saveWordList(list)
    }
}
