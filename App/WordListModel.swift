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
        persist(list.add(word))
    }

    func edit(at index: Int, to word: String) -> WordList.Outcome {
        persist(list.edit(at: index, to: word))
    }

    func delete(at offsets: IndexSet) {
        list.delete(at: offsets)
        persist(.added)
    }

    func importText(_ text: String) {
        list.importText(text)
        persist(.added)
    }

    private func persist(_ outcome: WordList.Outcome) -> WordList.Outcome {
        try? store?.saveWordList(list)
        return outcome
    }
}
