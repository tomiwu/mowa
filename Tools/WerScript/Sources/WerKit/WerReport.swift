/// The error count of one group.
public struct GroupScore: Equatable, Sendable {
    public let group: Group
    public var sentences = 0
    public var words = 0
    public var errors = 0

    public init(group: Group) {
        self.group = group
    }

    /// The WER in percent. It is 0 for a group without words.
    public var percent: Double {
        words == 0 ? 0 : Double(errors) * 100 / Double(words)
    }
}

public enum WerReport {
    /// The Polish WER target in percent (NFR5).
    public static let polishTarget = 9.0

    /// Scores every group. A sentence without hypothesis is an error.
    public static func score(
        sentences: [Sentence],
        hypotheses: [String: String]
    ) throws(WerError) -> [GroupScore] {
        var scores = Group.allCases.map { GroupScore(group: $0) }
        for sentence in sentences {
            guard let hypothesis = hypotheses[sentence.id] else {
                throw .missingHypothesis(sentence.id)
            }
            let reference = WordError.words(sentence.reference)
            let index = Group.allCases.firstIndex(of: sentence.group) ?? 0
            scores[index].sentences += 1
            scores[index].words += reference.count
            scores[index].errors += WordError.editDistance(reference, WordError.words(hypothesis))
        }
        return scores
    }

    /// One line per group, then the verdict for the Polish target.
    public static func format(_ scores: [GroupScore]) -> String {
        var lines = scores.map(line)
        if let polish = scores.first(where: { $0.group == .polish }) {
            lines.append(verdict(polish))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func line(_ score: GroupScore) -> String {
        let percent = twoDecimals(score.percent)
        return "\(score.group.rawValue): WER \(percent)% "
            + "(\(score.errors) errors, \(score.words) words, \(score.sentences) sentences)"
    }

    static func twoDecimals(_ value: Double) -> String {
        let hundredths = Int((value * 100).rounded())
        let fraction = hundredths % 100
        return "\(hundredths / 100)." + (fraction < 10 ? "0" : "") + "\(fraction)"
    }

    private static func verdict(_ polish: GroupScore) -> String {
        let met = polish.words > 0 && polish.percent <= polishTarget
        return "Polish target (<= 9%): " + (met ? "met" : "NOT met")
    }
}
