internal import Foundation

/// Identifies one function by its repository-relative file and its first line.
public struct FunctionKey: Hashable, Sendable {
    public let file: String
    public let line: Int

    public init(file: String, line: Int) {
        self.file = file
        self.line = line
    }
}

/// One function with its cyclomatic complexity from lizard.
public struct FunctionComplexity: Equatable, Sendable {
    public let key: FunctionKey
    public let name: String
    public let complexity: Int
    /// The last line of the function. Coverage may start on a later line than `key.line`.
    public let endLine: Int

    public init(key: FunctionKey, name: String, complexity: Int, endLine: Int? = nil) {
        self.key = key
        self.name = name
        self.complexity = complexity
        self.endLine = max(endLine ?? key.line, key.line)
    }
}

/// One line of the CRAP report.
public struct CrapRow: Equatable, Sendable {
    public let function: FunctionComplexity
    public let coverage: Double

    public init(function: FunctionComplexity, coverage: Double) {
        self.function = function
        self.coverage = coverage
    }

    public var crap: Double {
        CrapScore.value(complexity: function.complexity, coverage: coverage)
    }
}

public enum CrapScore {
    /// CRAP = comp^2 * (1 - cov)^3 + comp, with coverage limited to 0...1.
    public static func value(complexity: Int, coverage: Double) -> Double {
        let comp = Double(complexity)
        let uncovered = 1 - min(max(coverage, 0), 1)
        return comp * comp * pow(uncovered, 3) + comp
    }

    /// Joins complexity and coverage on file and start line. No coverage entry means 0.
    ///
    /// A multi-line signature can make xccov report a later line than lizard. Then the first
    /// coverage entry between the start line and the end line counts.
    public static func rows(
        complexities: [FunctionComplexity],
        coverage: [FunctionKey: Double]
    ) -> [CrapRow] {
        let linesByFile = Dictionary(grouping: coverage.keys, by: \.file).mapValues {
            $0.map(\.line).sorted()
        }
        return complexities.map { function in
            let key = function.key
            let line = linesByFile[key.file]?.first { $0 >= key.line }
            let match = line.flatMap { $0 <= function.endLine ? $0 : nil } ?? key.line
            return CrapRow(
                function: function,
                coverage: coverage[FunctionKey(file: key.file, line: match)] ?? 0
            )
        }
    }

    /// Keeps only functions with a coverage entry between the start line and the end line.
    /// A function without an entry was not compiled on this platform (for example `#if os(iOS)`).
    /// Only the local Linux gate uses this. The macOS CI gate counts such a function as 0%.
    public static func compiled(
        complexities: [FunctionComplexity],
        coverage: [FunctionKey: Double]
    ) -> [FunctionComplexity] {
        let files = Dictionary(grouping: coverage.keys, by: \.file)
        return complexities.filter { function in
            files[function.key.file, default: []].contains {
                (function.key.line...function.endLine).contains($0.line)
            }
        }
    }

    public static func failures(rows: [CrapRow], threshold: Double) -> [CrapRow] {
        rows.filter { $0.crap >= threshold }
    }
}
