import Foundation

/// Fuzzy correction with the personal word list (method (c) in `docs/BIASING_METHODS.md`).
///
/// A word in the text that is close to a term of the list is replaced with the term.
/// The comparison ignores case and diacritics. A term of up to 3 letters must match exactly,
/// a term of 4 to 6 letters can differ by 1 edit, a longer term by 2 edits.
/// The first letter must be the same.
public struct WordCorrector: Sendable, Equatable {
    private struct Term: Sendable, Equatable {
        let display: String
        let key: String
        let wordCount: Int

        init?(_ word: String) {
            let words = Self.words(of: word)
            guard !words.isEmpty else { return nil }
            display = words.joined(separator: " ")
            key = WordCorrector.fold(display)
            wordCount = words.count
        }

        var allowedEdits: Int {
            switch key.count {
            case ...3: 0
            case 4...6: 1
            default: 2
            }
        }

        func edits(to candidate: String) -> Int? {
            guard key.first == candidate.first else { return nil }
            let edits = EditDistance.between(key, candidate)
            return edits <= allowedEdits ? edits : nil
        }

        private static func words(of text: String) -> [String] {
            text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        }
    }

    private struct Match {
        let term: Term
        let edits: Int
        let length: Int
    }

    private let terms: [Term]

    public init(words: [String]) {
        terms = words.compactMap(Term.init)
    }

    /// The text with each word that is close to a term replaced by the term.
    public func correct(_ text: String) -> String {
        guard !terms.isEmpty else { return text }
        let tokens = Self.tokens(of: text)
        var output = ""
        var index = 0
        while index < tokens.count {
            let match = match(in: tokens, at: index)
            output += match?.term.display ?? tokens[index].text
            index += match?.length ?? 1
        }
        return output
    }

    private func match(in tokens: [Token], at index: Int) -> Match? {
        guard tokens[index].isWord else { return nil }
        return terms.compactMap { match($0, in: tokens, at: index) }
            .min { ($0.edits, -$0.length) < ($1.edits, -$1.length) }
    }

    private func match(_ term: Term, in tokens: [Token], at index: Int) -> Match? {
        guard let length = Self.windowLength(words: term.wordCount, in: tokens, at: index) else {
            return nil
        }
        let window = tokens[index..<(index + length)].filter(\.isWord).map(\.text)
        let candidate = Self.fold(window.joined(separator: " "))
        return term.edits(to: candidate).map { Match(term: term, edits: $0, length: length) }
    }

    /// The number of tokens for a number of words. Spaces must separate the words.
    private static func windowLength(words: Int, in tokens: [Token], at index: Int) -> Int? {
        let length = 2 * words - 1
        guard index + length <= tokens.count else { return nil }
        let window = tokens[index..<(index + length)]
        let fits = window.enumerated().allSatisfy { $0.element.fits(wordSlot: $0.offset % 2 == 0) }
        return fits ? length : nil
    }

    fileprivate static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "ł", with: "l")
    }

    private static func tokens(of text: String) -> [Token] {
        var tokens: [Token] = []
        for character in text {
            let isWord = character.isLetter || character.isNumber
            if let last = tokens.last, last.isWord == isWord {
                tokens[tokens.count - 1].text.append(character)
            } else {
                tokens.append(Token(text: String(character), isWord: isWord))
            }
        }
        return tokens
    }
}

private struct Token: Sendable {
    var text: String
    let isWord: Bool

    /// A word slot holds a word. The slot between two words holds spaces only.
    func fits(wordSlot: Bool) -> Bool {
        wordSlot ? isWord : (!isWord && text.allSatisfy(\.isWhitespace))
    }
}
