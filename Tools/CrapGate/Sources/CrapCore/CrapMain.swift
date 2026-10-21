internal import Foundation

/// The command line behavior: `CrapGate <root> <threshold> <lizard.csv> <xccov.json>...`.
public enum CrapMain {
    struct Options {
        let root: String
        let threshold: Double
        let lizardPath: String
        let xccovPaths: [String]
    }

    public static let csvHeader = "file,line,function,ccn,coverage,crap"

    /// Runs the gate with real files. Returns the process exit code.
    public static func runWithFiles(
        arguments: [String],
        write: (String) -> Void,
        writeError: (String) -> Void
    ) -> Int32 {
        run(arguments: arguments, read: readFile, write: write, writeError: writeError)
    }

    /// Returns 0 when all functions pass, 1 when a function fails, 2 when an input is bad.
    public static func run(
        arguments: [String],
        read: (String) throws -> String,
        write: (String) -> Void,
        writeError: (String) -> Void
    ) -> Int32 {
        do {
            let options = try options(arguments)
            let rows = try buildRows(options: options, read: read)
            write(csv(rows))
            return report(rows, threshold: options.threshold, to: writeError)
        } catch {
            writeError("CrapGate error: \(error)\n")
            return 2
        }
    }

    static func buildRows(
        options: Options,
        read: (String) throws -> String
    ) throws(CrapError) -> [CrapRow] {
        let complexities = try LizardParser.parse(try readText(options.lizardPath, read))
        let maps = try options.xccovPaths.map { (path) throws(CrapError) in
            try XccovParser.parse(try readText(path, read), root: options.root)
        }
        return CrapScore.rows(complexities: complexities, coverage: XccovParser.merge(maps))
    }

    static func options(_ arguments: [String]) throws(CrapError) -> Options {
        guard arguments.count >= 4, let threshold = Double(arguments[1]) else { throw .usage }
        return Options(
            root: arguments[0],
            threshold: threshold,
            lizardPath: arguments[2],
            xccovPaths: Array(arguments[3...])
        )
    }

    static func readText(
        _ path: String,
        _ read: (String) throws -> String
    ) throws(CrapError) -> String {
        do {
            return try read(path)
        } catch {
            throw .unreadable(path)
        }
    }

    static func readFile(_ path: String) throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }

    static func report(_ rows: [CrapRow], threshold: Double, to writeError: (String) -> Void)
        -> Int32
    {
        let failed = CrapScore.failures(rows: rows, threshold: threshold)
        failed.forEach { writeError("CRAP \(format($0.crap)) >= \(threshold): \(label($0))\n") }
        return failed.isEmpty ? 0 : 1
    }

    static func csv(_ rows: [CrapRow]) -> String {
        let sorted = rows.sorted {
            ($0.function.key.file, $0.function.key.line) < (
                $1.function.key.file, $1.function.key.line
            )
        }
        return ([csvHeader] + sorted.map(csvLine)).joined(separator: "\n") + "\n"
    }

    static func csvLine(_ row: CrapRow) -> String {
        let function = row.function
        let name = "\"" + function.name.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        return [
            function.key.file, String(function.key.line), name, String(function.complexity),
            format(row.coverage), format(row.crap),
        ].joined(separator: ",")
    }

    static func label(_ row: CrapRow) -> String {
        "\(row.function.key.file):\(row.function.key.line) \(row.function.name)"
    }

    static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
