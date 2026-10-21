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

    public init(key: FunctionKey, name: String, complexity: Int) {
        self.key = key
        self.name = name
        self.complexity = complexity
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
    public static func rows(
        complexities: [FunctionComplexity],
        coverage: [FunctionKey: Double]
    ) -> [CrapRow] {
        complexities.map { CrapRow(function: $0, coverage: coverage[$0.key] ?? 0) }
    }

    public static func failures(rows: [CrapRow], threshold: Double) -> [CrapRow] {
        rows.filter { $0.crap >= threshold }
    }
}
