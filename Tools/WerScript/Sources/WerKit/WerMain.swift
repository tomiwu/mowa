/// The command line behavior: `wer <test set.tsv> <hypotheses.tsv>`.
public enum WerMain {
    /// Returns 0 on success and 2 on bad input.
    public static func run(
        arguments: [String],
        read: (String) throws -> String,
        write: (String) -> Void,
        writeError: (String) -> Void
    ) -> Int32 {
        do {
            write(try report(arguments: arguments, read: read))
            return 0
        } catch {
            writeError("wer: \(error)\n")
            return 2
        }
    }

    private static func report(
        arguments: [String],
        read: (String) throws -> String
    ) throws -> String {
        guard arguments.count == 2 else { throw WerError.usage }
        let sentences = try TestSet.parseSentences(try read(arguments[0]))
        let hypotheses = try TestSet.parseHypotheses(try read(arguments[1]))
        return WerReport.format(try WerReport.score(sentences: sentences, hypotheses: hypotheses))
    }
}
