/// Reads the CSV that `lizard --csv` prints.
///
/// Columns: NLOC, CCN, tokens, params, length, "name@start-end@file", file, name, long name,
/// start line, end line.
public enum LizardParser {
    public static func parse(_ csv: String) throws(CrapError) -> [FunctionComplexity] {
        let lines = csv.split(whereSeparator: \.isNewline)
        let functions = try lines.map { (line) throws(CrapError) in try parseLine(line) }
        guard !functions.isEmpty else { throw .noFunctions }
        return functions
    }

    static func parseLine(_ line: Substring) throws(CrapError) -> FunctionComplexity {
        let fields = CSVSplitter.split(line)
        guard fields.count >= 11, let ccn = Int(fields[1]), let start = Int(fields[9]),
            let end = Int(fields[10])
        else {
            throw .malformedLizardLine(String(line))
        }
        let key = FunctionKey(file: fields[6], line: start)
        return FunctionComplexity(key: key, name: fields[7], complexity: ccn, endLine: end)
    }
}

/// Splits one CSV line. A comma inside double quotes does not split.
struct CSVSplitter {
    private var fields: [String] = []
    private var current = ""
    private var inQuotes = false

    static func split(_ line: Substring) -> [String] {
        var splitter = Self()
        line.forEach { splitter.feed($0) }
        return splitter.finish()
    }

    private mutating func feed(_ character: Character) {
        if character == "\"" {
            inQuotes.toggle()
            return
        }
        if character == ",", !inQuotes {
            fields.append(current)
            current = ""
            return
        }
        current.append(character)
    }

    private func finish() -> [String] {
        fields + [current]
    }
}
