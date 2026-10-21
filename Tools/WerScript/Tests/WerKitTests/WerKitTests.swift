import Testing

@testable import WerKit

struct WordErrorTests {
    @Test func wordsDropPunctuationAndCase() {
        #expect(WordError.words("Cześć, Świecie! It's OK.") == ["cześć", "świecie", "it's", "ok"])
    }

    @Test func emptyTextHasNoWords() {
        #expect(WordError.words(" ,. ").isEmpty)
    }

    @Test func equalListsHaveDistanceZero() {
        #expect(WordError.editDistance(["a", "b"], ["a", "b"]) == 0)
    }

    @Test func countsSubstitutionDeletionAndInsertion() {
        #expect(WordError.editDistance(["a", "b", "c"], ["a", "x", "c"]) == 1)
        #expect(WordError.editDistance(["a", "b", "c"], ["a", "c"]) == 1)
        #expect(WordError.editDistance(["a", "c"], ["a", "b", "c"]) == 1)
    }

    @Test func emptyHypothesisDeletesAllWords() {
        #expect(WordError.editDistance(["a", "b"], []) == 2)
        #expect(WordError.editDistance([], ["a"]) == 1)
    }
}

struct TestSetTests {
    @Test func parsesSentencesAndSkipsComments() throws {
        let text = "# note\n\npl1\tpolish\tDzień dobry\nmx1\tmixed\tOpen the plik\n"
        let sentences = try TestSet.parseSentences(text)
        #expect(sentences.count == 2)
        #expect(sentences[0] == Sentence(id: "pl1", group: .polish, reference: "Dzień dobry"))
        #expect(sentences[1].group == .mixed)
    }

    @Test func rejectsUnknownGroup() {
        #expect(throws: WerError.unknownGroup("french")) {
            try TestSet.parseSentences("a\tfrench\tbonjour")
        }
    }

    @Test func rejectsBadLine() {
        #expect(throws: WerError.badLine("only one field")) {
            try TestSet.parseSentences("only one field")
        }
    }

    @Test func parsesHypotheses() throws {
        let map = try TestSet.parseHypotheses("a\thello world\nb\t\n")
        #expect(map == ["a": "hello world", "b": ""])
    }
}

struct WerReportTests {
    private let sentences = [
        Sentence(id: "p", group: .polish, reference: "jeden dwa trzy cztery"),
        Sentence(id: "e", group: .english, reference: "one two"),
    ]

    @Test func scoresEachGroup() throws {
        let scores = try WerReport.score(
            sentences: sentences,
            hypotheses: ["p": "jeden dwa trzy", "e": "one two"]
        )
        #expect(scores[0].errors == 1)
        #expect(scores[0].words == 4)
        #expect(scores[0].percent == 25)
        #expect(scores[1].percent == 0)
        #expect(scores[2].sentences == 0)
        #expect(scores[2].percent == 0)
    }

    @Test func missingHypothesisThrows() {
        #expect(throws: WerError.missingHypothesis("e")) {
            try WerReport.score(sentences: sentences, hypotheses: ["p": ""])
        }
    }

    @Test func formatsGroupsAndVerdictNotMet() throws {
        let scores = try WerReport.score(
            sentences: sentences,
            hypotheses: ["p": "jeden dwa trzy", "e": "one two"]
        )
        let text = WerReport.format(scores)
        #expect(text.contains("polish: WER 25.00% (1 errors, 4 words, 1 sentences)"))
        #expect(text.contains("mixed: WER 0.00%"))
        #expect(text.contains("Polish target (<= 9%): NOT met"))
    }

    @Test func verdictMetAtTarget() throws {
        let text = WerReport.format(
            try WerReport.score(
                sentences: [Sentence(id: "p", group: .polish, reference: "a b c d e f g h i j")],
                hypotheses: ["p": "a b c d e f g h i"]
            )
        )
        #expect(text.contains("Polish target (<= 9%): NOT met"))
        let ok = WerReport.format(
            try WerReport.score(
                sentences: [Sentence(id: "p", group: .polish, reference: "a b c d e f g h i j k")],
                hypotheses: ["p": "a b c d e f g h i j k"]
            )
        )
        #expect(ok.contains("Polish target (<= 9%): met"))
    }

    @Test func roundsToTwoDecimals() {
        #expect(WerReport.twoDecimals(7.3149) == "7.31")
        #expect(WerReport.twoDecimals(5.05) == "5.05")
    }
}

struct WerMainTests {
    private func run(_ args: [String], files: [String: String]) -> (Int32, String, String) {
        var out = ""
        var err = ""
        let code = WerMain.run(
            arguments: args,
            read: { path in
                guard let text = files[path] else { throw WerError.usage }
                return text
            },
            write: { out += $0 },
            writeError: { err += $0 }
        )
        return (code, out, err)
    }

    @Test func printsReport() {
        let (code, out, _) = run(
            ["s", "h"],
            files: ["s": "a\tpolish\tx y\n", "h": "a\tx y\n"]
        )
        #expect(code == 0)
        #expect(out.contains("polish: WER 0.00%"))
    }

    @Test func wrongArgumentCountFails() {
        let (code, _, err) = run([], files: [:])
        #expect(code == 2)
        #expect(err.contains("usage"))
    }
}
