import Foundation

/// The personal word list: names and terms that the app writes correctly.
public struct WordList: Equatable, Sendable {
    /// The result of an add or an edit.
    public enum Outcome: Equatable, Sendable {
        case added
        case empty
        case duplicate
        case missing
    }

    public private(set) var words: [String]

    public init(words: [String] = []) {
        self.words = words
    }

    /// Adds a word. The word is trimmed. A duplicate ignores the case.
    @discardableResult
    public mutating func add(_ word: String) -> Outcome {
        let trimmed = Self.trimmed(word)
        let outcome = check(trimmed, ignoring: nil)
        if outcome == .added { words.append(trimmed) }
        return outcome
    }

    /// Replaces the word at an index.
    @discardableResult
    public mutating func edit(at index: Int, to word: String) -> Outcome {
        guard words.indices.contains(index) else { return .missing }
        let trimmed = Self.trimmed(word)
        let outcome = check(trimmed, ignoring: index)
        if outcome == .added { words[index] = trimmed }
        return outcome
    }

    /// Removes the words at the indexes. Indexes out of range are ignored.
    public mutating func delete(at indexes: some Sequence<Int>) {
        let removed = Set(indexes)
        words = words.enumerated().filter { !removed.contains($0.offset) }.map(\.element)
    }

    /// The list as text, one word on each line.
    public var exportedText: String {
        words.map { $0 + "\n" }.joined()
    }

    /// Adds the words of a text, one on each line. Returns the number of added words.
    @discardableResult
    public mutating func importText(_ text: String) -> Int {
        let before = words.count
        for line in text.split(whereSeparator: \.isNewline) { add(String(line)) }
        return words.count - before
    }

    private func check(_ word: String, ignoring index: Int?) -> Outcome {
        guard !word.isEmpty else { return .empty }
        let taken = words.enumerated().contains {
            $0.offset != index && $0.element.caseInsensitiveCompare(word) == .orderedSame
        }
        return taken ? .duplicate : .added
    }

    private static func trimmed(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
