internal import Foundation

/// Reads the JSON that `llvm-cov export` prints. SwiftPM writes this file for
/// `swift test --enable-code-coverage` (see `--show-codecov-path`). It works on Linux.
///
/// The coverage of a function is the part of its code regions that ran at least once.
/// The key line is the first line of the first region (the function body).
public enum LlvmCovParser {
    struct Export: Decodable {
        let type: String
        let data: [Payload]
    }

    struct Payload: Decodable {
        let functions: [Function]
    }

    struct Function: Decodable {
        let filenames: [String]
        let regions: [[Int]]
    }

    /// The `type` value of an `llvm-cov export` JSON file.
    public static let exportType = "llvm.coverage.json.export"

    /// Region fields: lineStart, colStart, lineEnd, colEnd, count, fileID, expandedFileID, kind.
    static let countIndex = 4
    static let fileIndex = 5
    static let kindIndex = 7
    static let regionFields = 8

    public static func isExport(_ json: String) -> Bool {
        (try? JSONDecoder().decode(Export.self, from: Data(json.utf8)))?.type == exportType
    }

    /// Returns region coverage per function. File paths lose the `root` prefix.
    public static func parse(_ json: String, root: String) throws(CrapError) -> [FunctionKey:
        Double]
    {
        let functions = try decode(json).data.flatMap(\.functions)
        let entries = functions.flatMap { entry(for: $0, root: root) }
        return Dictionary(entries, uniquingKeysWith: max)
    }

    static func entry(for function: Function, root: String) -> [(FunctionKey, Double)] {
        let code = function.regions.filter(isCode)
        guard let first = code.first else { return [] }
        let covered = code.filter(ran).count
        let file = XccovParser.relativePath(fileName(function), root: root)
        return [(FunctionKey(file: file, line: first[0]), Double(covered) / Double(code.count))]
    }

    /// A code region (kind 0) in the function's own file (file id 0).
    static func isCode(_ region: [Int]) -> Bool {
        region.count >= regionFields && region[fileIndex] == 0 && region[kindIndex] == 0
    }

    static func fileName(_ function: Function) -> String {
        function.filenames.first ?? ""
    }

    static func ran(_ region: [Int]) -> Bool {
        region[countIndex] > 0
    }

    static func decode(_ json: String) throws(CrapError) -> Export {
        do {
            return try JSONDecoder().decode(Export.self, from: Data(json.utf8))
        } catch {
            throw .invalidLlvmCov("\(error)")
        }
    }
}
