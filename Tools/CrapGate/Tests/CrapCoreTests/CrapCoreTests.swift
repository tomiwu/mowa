import Foundation
import Testing

@testable import CrapCore

private let lizardCSV = """
    4,1,18,0,4,"a@5-8@App/A.swift","App/A.swift","a","a",5,8
    9,3,30,2,9,"b@10-18@App/B.swift","App/B.swift","b","b(x, y)",10,18
    """

private func xccov(file: String, line: Int, coverage: Double) -> String {
    """
    {"targets":[{"name":"T","files":[{"path":"\(file)","functions":[
    {"name":"f","lineNumber":\(line),"lineCoverage":\(coverage),"executionCount":1}]}]}]}
    """
}

struct CrapScoreTests {
    @Test func fullCoverageGivesComplexity() {
        #expect(CrapScore.value(complexity: 3, coverage: 1) == 3)
    }

    @Test func noCoverageGivesSquarePlusComplexity() {
        #expect(CrapScore.value(complexity: 3, coverage: 0) == 12)
    }

    @Test func coverageIsLimitedToUnitRange() {
        #expect(CrapScore.value(complexity: 2, coverage: 5) == 2)
        #expect(CrapScore.value(complexity: 2, coverage: -1) == 6)
    }

    @Test func missingCoverageCountsAsZero() {
        let function = FunctionComplexity(
            key: FunctionKey(file: "A.swift", line: 1),
            name: "a",
            complexity: 2
        )
        let rows = CrapScore.rows(complexities: [function], coverage: [:])
        #expect(rows.map(\.coverage) == [0])
        #expect(rows.map(\.crap) == [6])
    }

    @Test func coverageOnLaterSignatureLineIsUsed() {
        let function = FunctionComplexity(
            key: FunctionKey(file: "A.swift", line: 1),
            name: "a",
            complexity: 2,
            endLine: 6
        )
        let coverage = [
            FunctionKey(file: "A.swift", line: 3): 0.75,
            FunctionKey(file: "A.swift", line: 9): 1,
        ]
        #expect(
            CrapScore.rows(complexities: [function], coverage: coverage).map(\.coverage) == [0.75]
        )
        let outside = [FunctionKey(file: "A.swift", line: 9): 1.0]
        #expect(CrapScore.rows(complexities: [function], coverage: outside).map(\.coverage) == [0])
    }

    @Test func failuresUseInclusiveThreshold() {
        let function = FunctionComplexity(
            key: FunctionKey(file: "A.swift", line: 1),
            name: "a",
            complexity: 4
        )
        let rows = [CrapRow(function: function, coverage: 1)]
        #expect(CrapScore.failures(rows: rows, threshold: 4).count == 1)
        #expect(CrapScore.failures(rows: rows, threshold: 4.5).isEmpty)
    }
}

struct LizardParserTests {
    @Test func parsesFunctionsWithQuotedCommas() throws {
        let functions = try LizardParser.parse(lizardCSV)
        #expect(functions.map(\.name) == ["a", "b"])
        #expect(functions.map(\.complexity) == [1, 3])
        #expect(functions[1].key == FunctionKey(file: "App/B.swift", line: 10))
    }

    @Test func emptyOutputIsAnError() {
        #expect(throws: CrapError.noFunctions) { try LizardParser.parse("\n") }
    }

    @Test func shortLineIsAnError() {
        #expect(throws: CrapError.malformedLizardLine("1,2")) { try LizardParser.parse("1,2") }
    }

    @Test func nonNumericComplexityIsAnError() {
        let line = "4,x,18,0,4,\"a\",\"A.swift\",\"a\",\"a\",5,8"
        #expect(throws: CrapError.malformedLizardLine(line)) { try LizardParser.parse(line) }
    }
}

struct XccovParserTests {
    @Test func stripsRootAndReadsCoverage() throws {
        let json = xccov(file: "/work/mowa/App/A.swift", line: 5, coverage: 0.5)
        let map = try XccovParser.parse(json, root: "/work/mowa")
        #expect(map == [FunctionKey(file: "App/A.swift", line: 5): 0.5])
    }

    @Test func keepsPathOutsideRoot() {
        #expect(XccovParser.relativePath("/other/A.swift", root: "/work/") == "/other/A.swift")
        #expect(XccovParser.relativePath("/work/A.swift", root: "/work/") == "A.swift")
    }

    @Test func mergeKeepsBestCoverage() {
        let key = FunctionKey(file: "A.swift", line: 1)
        #expect(XccovParser.merge([[key: 0.2], [key: 0.9], [key: 0.5]]) == [key: 0.9])
    }

    @Test func badJSONIsAnError() {
        #expect(throws: (any Error).self) { try XccovParser.parse("{", root: "/") }
    }
}

private struct RunResult {
    let code: Int32
    let out: String
    let err: String
}

struct CrapMainTests {
    private func files(_ coverage: Double) -> [String: String] {
        [
            "l.csv": lizardCSV,
            "x.json": xccov(file: "/r/App/B.swift", line: 10, coverage: coverage),
        ]
    }

    private func run(_ files: [String: String], _ args: [String]) -> RunResult {
        var out = ""
        var err = ""
        let code = CrapMain.run(
            arguments: args,
            read: { path in
                guard let text = files[path] else { throw CrapError.unreadable(path) }
                return text
            },
            write: { out += $0 },
            writeError: { err += $0 }
        )
        return RunResult(code: code, out: out, err: err)
    }

    @Test func passesAndPrintsCsv() {
        let result = run(files(1), ["/r", "4", "l.csv", "x.json"])
        #expect(result.code == 0)
        #expect(result.err.isEmpty)
        #expect(
            result.out == """
                file,line,function,ccn,coverage,crap
                App/A.swift,5,"a",1,0.00,2.00
                App/B.swift,10,"b",3,1.00,3.00

                """
        )
    }

    @Test func failsWhenCrapIsTooHigh() {
        let result = run(files(0), ["/r", "4", "l.csv", "x.json"])
        #expect(result.code == 1)
        #expect(result.err == "CRAP 12.00 >= 4.0: App/B.swift:10 b\n")
    }

    @Test func usageErrorGivesCodeTwo() {
        let result = run([:], ["/r"])
        #expect(result.code == 2)
        #expect(result.err.contains("usage"))
    }

    @Test func badThresholdGivesCodeTwo() {
        #expect(run(files(1), ["/r", "x", "l.csv", "x.json"]).code == 2)
    }

    @Test func missingFileGivesCodeTwo() {
        let result = run([:], ["/r", "4", "l.csv", "x.json"])
        #expect(result.code == 2)
        #expect(result.err.contains("unreadable"))
    }

    @Test func missingXccovFileGivesCodeTwo() {
        let only = ["l.csv": lizardCSV]
        #expect(run(only, ["/r", "4", "l.csv", "x.json"]).code == 2)
    }

    @Test func quotesInNamesAreEscaped() {
        let row = CrapRow(
            function: FunctionComplexity(
                key: FunctionKey(file: "A.swift", line: 1),
                name: "a\"b",
                complexity: 1
            ),
            coverage: 1
        )
        #expect(CrapMain.csvLine(row) == "A.swift,1,\"a\"\"b\",1,1.00,1.00")
    }

    @Test func readsRealFiles() throws {
        #expect(throws: (any Error).self) { try CrapMain.readFile("/nonexistent/file") }
        let path = "/tmp/crapgate-read-test-\(UInt32.random(in: 0...UInt32.max)).txt"
        try "hello".write(toFile: path, atomically: true, encoding: .utf8)
        #expect(try CrapMain.readFile(path) == "hello")
    }

    @Test func runWithFilesReportsMissingInput() {
        var err = ""
        let code = CrapMain.runWithFiles(
            arguments: ["/r", "4", "/nonexistent/l.csv", "/nonexistent/x.json"],
            write: { _ in },
            writeError: { err += $0 }
        )
        #expect(code == 2)
        #expect(!err.isEmpty)
    }
}
