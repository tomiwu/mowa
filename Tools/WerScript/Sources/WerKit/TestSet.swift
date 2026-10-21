/// A reference sentence from the test set file.
public struct Sentence: Equatable, Sendable {
    public let id: String
    public let group: Group
    public let reference: String
}

/// Parses tab-separated files. Empty lines and lines that start with `#` are ignored.
public enum TestSet {
    /// Each line is `id<TAB>group<TAB>reference`.
    public static func parseSentences(_ text: String) throws(WerError) -> [Sentence] {
        var sentences: [Sentence] = []
        for fields in try rows(text, count: 3) {
            guard let group = Group(rawValue: fields[1]) else {
                throw .unknownGroup(fields[1])
            }
            sentences.append(Sentence(id: fields[0], group: group, reference: fields[2]))
        }
        return sentences
    }

    /// Each line is `id<TAB>hypothesis`. The result maps the id to the engine text.
    public static func parseHypotheses(_ text: String) throws(WerError) -> [String: String] {
        var result: [String: String] = [:]
        for fields in try rows(text, count: 2) {
            result[fields[0]] = fields[1]
        }
        return result
    }

    private static func rows(_ text: String, count: Int) throws(WerError) -> [[String]] {
        var result: [[String]] = []
        for line in text.split(separator: "\n") where !isSkipped(line) {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count == count else { throw .badLine(String(line)) }
            result.append(fields.map(String.init))
        }
        return result
    }

    private static func isSkipped(_ line: Substring) -> Bool {
        line.allSatisfy { $0 == " " } || line.hasPrefix("#")
    }
}
