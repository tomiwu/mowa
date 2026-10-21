import Testing

@testable import MowaCore

struct WordCorrectorTests {
    private let corrector = WordCorrector(words: [
        "Wrocław", "Zbigniew", "Kubernetes", "GitHub", "Gdynia", "Ala",
    ])

    @Test func emptyListKeepsText() {
        #expect(WordCorrector(words: []).correct("jadę do Wrocławia") == "jadę do Wrocławia")
    }

    @Test func blankTermsAreIgnored() {
        #expect(WordCorrector(words: ["  ", "!"]).correct("tekst") == "tekst")
    }

    @Test func fixesCase() {
        #expect(corrector.correct("mieszkam w wrocław") == "mieszkam w Wrocław")
    }

    @Test func fixesDiacritics() {
        #expect(corrector.correct("jade do Wroclaw") == "jade do Wrocław")
    }

    @Test func fixesOneEditInShortTerm() {
        #expect(corrector.correct("pojechałem do Gdyna") == "pojechałem do Gdynia")
        #expect(corrector.correct("Gdinia jest nad morzem") == "Gdynia jest nad morzem")
    }

    @Test func fixesTwoEditsInLongTerm() {
        #expect(corrector.correct("uruchom Kubernetis") == "uruchom Kubernetes")
        #expect(corrector.correct("uruchom Cubernetes") == "uruchom Cubernetes")
        #expect(corrector.correct("Kubernates i Kubernetis") == "Kubernetes i Kubernetes")
    }

    @Test func keepsWordsThatAreFarFromTerms() {
        #expect(corrector.correct("To jest zwykłe zdanie.") == "To jest zwykłe zdanie.")
    }

    @Test func shortTermNeedsExactMatch() {
        #expect(corrector.correct("Ola i ala") == "Ola i Ala")
    }

    @Test func keepsPunctuationAndSpaces() {
        #expect(corrector.correct("  Zbigniev,  to ty? ") == "  Zbigniew,  to ty? ")
    }

    @Test func firstLetterMustMatch() {
        #expect(corrector.correct("Gdynia") == "Gdynia")
        #expect(WordCorrector(words: ["Marek"]).correct("barek") == "barek")
    }

    @Test func correctsTermsOfTwoWords() {
        let corrector = WordCorrector(words: ["New York", "Jan"])
        #expect(corrector.correct("w new  york jest") == "w New York jest")
        #expect(corrector.correct("w new, york jest") == "w new, york jest")
        #expect(corrector.correct("new") == "new")
    }

    @Test func prefersTheExactTerm() {
        let corrector = WordCorrector(words: ["Anna", "Ania"])
        #expect(corrector.correct("ania") == "Ania")
    }

    @Test func nameAccuracyReachesTarget() {
        let cases: [(spoken: String, name: String)] = [
            ("wrocław", "Wrocław"), ("Wroclaw", "Wrocław"), ("Wrocłav", "Wrocław"),
            ("zbigniev", "Zbigniew"), ("Zbigniew", "Zbigniew"), ("zbignew", "Zbigniew"),
            ("kubernetis", "Kubernetes"), ("Kubernates", "Kubernetes"),
            ("kubernetes", "Kubernetes"), ("github", "GitHub"), ("Githab", "GitHub"),
            ("Gdinia", "Gdynia"), ("gdynia", "Gdynia"), ("Gdyna", "Gdynia"),
        ]
        let correct = cases.filter {
            corrector.correct("to jest \($0.spoken) dziś") == "to jest \($0.name) dziś"
        }
        #expect(Double(correct.count) / Double(cases.count) >= 0.9)
    }
}
