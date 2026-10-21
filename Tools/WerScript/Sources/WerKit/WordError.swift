/// Word-level error counting for the word error rate (WER).
public enum WordError {
    /// Splits text into lower-case words. Punctuation is dropped. An apostrophe or a hyphen
    /// inside a word stays.
    public static func words(_ text: String) -> [String] {
        let cleaned = text.lowercased().map { keeps($0) ? $0 : " " }
        return String(cleaned).split(separator: " ").map(String.init)
    }

    /// The number of substitutions, deletions and insertions between two word lists.
    public static func editDistance(_ reference: [String], _ hypothesis: [String]) -> Int {
        var row = Array(0...hypothesis.count)
        for (index, refWord) in reference.enumerated() {
            row = nextRow(row, firstCell: index + 1, refWord: refWord, hypothesis: hypothesis)
        }
        return row[hypothesis.count]
    }

    private static func keeps(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "'" || character == "-"
    }

    private static func nextRow(
        _ previous: [Int],
        firstCell: Int,
        refWord: String,
        hypothesis: [String]
    ) -> [Int] {
        var row = [firstCell]
        for (column, hypWord) in hypothesis.enumerated() {
            let substitution = previous[column] + (refWord == hypWord ? 0 : 1)
            row.append(min(substitution, previous[column + 1] + 1, row[column] + 1))
        }
        return row
    }
}
