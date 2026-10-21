import Foundation
import Testing

@testable import MowaShared

struct WordListTests {
    @Test func addTrimsAndAppends() {
        var list = WordList(words: ["Wrocław"])
        #expect(list.add("  Kubernetes \n") == .added)
        #expect(list.words == ["Wrocław", "Kubernetes"])
    }

    @Test func addRejectsEmptyWord() {
        var list = WordList()
        #expect(list.add("   ") == .empty)
        #expect(list.words.isEmpty)
    }

    @Test func addRejectsDuplicateIgnoringCase() {
        var list = WordList(words: ["Zbigniew"])
        #expect(list.add("zbigniew") == .duplicate)
        #expect(list.words == ["Zbigniew"])
    }

    @Test func submitEditsWhenIndexIsGiven() {
        var list = WordList(words: ["Anna"])
        #expect(list.submit("Ola", editing: 0) == .added)
        #expect(list.words == ["Ola"])
    }

    @Test func submitAddsWhenThereIsNoIndex() {
        var list = WordList(words: ["Anna"])
        #expect(list.submit("Ola", editing: nil) == .added)
        #expect(list.words == ["Anna", "Ola"])
    }

    @Test func editReplacesWord() {
        var list = WordList(words: ["a", "b"])
        #expect(list.edit(at: 1, to: " c ") == .added)
        #expect(list.words == ["a", "c"])
    }

    @Test func editAllowsChangeOfCase() {
        var list = WordList(words: ["kubernetes"])
        #expect(list.edit(at: 0, to: "Kubernetes") == .added)
        #expect(list.words == ["Kubernetes"])
    }

    @Test func editRejectsDuplicateOfOtherWord() {
        var list = WordList(words: ["a", "b"])
        #expect(list.edit(at: 1, to: "A") == .duplicate)
        #expect(list.words == ["a", "b"])
    }

    @Test func editRejectsEmptyWord() {
        var list = WordList(words: ["a"])
        #expect(list.edit(at: 0, to: "") == .empty)
        #expect(list.words == ["a"])
    }

    @Test func editIgnoresBadIndex() {
        var list = WordList(words: ["a"])
        #expect(list.edit(at: 5, to: "b") == .missing)
        #expect(list.edit(at: -1, to: "b") == .missing)
        #expect(list.words == ["a"])
    }

    @Test func deleteRemovesWords() {
        var list = WordList(words: ["a", "b", "c"])
        list.delete(at: [0, 2])
        #expect(list.words == ["b"])
    }

    @Test func deleteIgnoresBadIndex() {
        var list = WordList(words: ["a"])
        list.delete(at: [3])
        #expect(list.words == ["a"])
    }

    @Test func exportJoinsLines() {
        #expect(WordList(words: ["a", "b"]).exportedText == "a\nb\n")
        #expect(WordList().exportedText.isEmpty)
    }

    @Test func importSkipsBlankAndDuplicateLines() {
        var list = WordList(words: ["a"])
        let count = list.importText("A\r\n b \n\n\nc\nb\n")
        #expect(count == 2)
        #expect(list.words == ["a", "b", "c"])
    }

    @Test func exportThenImportRoundTrips() {
        let source = WordList(words: ["Wrocław", "Łódź"])
        var target = WordList()
        _ = target.importText(source.exportedText)
        #expect(target == source)
    }

    @Test func storeSavesAndLoadsList() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = SharedStore(directory: directory)
        try store.saveWordList(WordList(words: ["x"]))
        #expect(try store.loadWordList() == WordList(words: ["x"]))
        #expect(try store.readWordList() == ["x"])
    }
}
