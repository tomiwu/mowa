/// The edit distance between two texts.
enum EditDistance {
    /// The number of insertions, deletions and substitutions that turn one text into the other.
    static func between(_ first: String, _ second: String) -> Int {
        let left = Array(first)
        let right = Array(second)
        var previous = Array(0...right.count)
        for (row, leftCharacter) in left.enumerated() {
            previous = nextRow(after: previous, row: row + 1, left: leftCharacter, right: right)
        }
        return previous[right.count]
    }

    private static func nextRow(
        after previous: [Int],
        row: Int,
        left: Character,
        right: [Character]
    ) -> [Int] {
        var current = [row]
        for (column, rightCharacter) in right.enumerated() {
            let substitution = previous[column] + (left == rightCharacter ? 0 : 1)
            current.append(min(substitution, previous[column + 1] + 1, current[column] + 1))
        }
        return current
    }
}
