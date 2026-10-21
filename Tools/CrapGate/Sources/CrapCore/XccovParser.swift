internal import Foundation

/// Reads the JSON that `xcrun xccov view --report --json` prints.
public enum XccovParser {
    struct Report: Decodable {
        let targets: [Target]
    }

    struct Target: Decodable {
        let files: [File]
    }

    struct File: Decodable {
        let path: String
        let functions: [Function]
    }

    struct Function: Decodable {
        let lineNumber: Int
        let lineCoverage: Double
    }

    /// Returns line coverage per function. File paths lose the `root` prefix.
    public static func parse(_ json: String, root: String) throws(CrapError) -> [FunctionKey:
        Double]
    {
        let report = try decode(json)
        let entries = report.targets.flatMap(\.files).flatMap { file in
            file.functions.map { function in
                (
                    FunctionKey(
                        file: relativePath(file.path, root: root),
                        line: function.lineNumber
                    ),
                    function.lineCoverage
                )
            }
        }
        return Dictionary(entries, uniquingKeysWith: max)
    }

    /// Keeps the best coverage when several reports list the same function.
    public static func merge(_ maps: [[FunctionKey: Double]]) -> [FunctionKey: Double] {
        maps.reduce(into: [:]) { $0.merge($1, uniquingKeysWith: max) }
    }

    static func relativePath(_ path: String, root: String) -> String {
        let prefix = root.hasSuffix("/") ? root : root + "/"
        return path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
    }

    static func decode(_ json: String) throws(CrapError) -> Report {
        do {
            return try JSONDecoder().decode(Report.self, from: Data(json.utf8))
        } catch {
            throw .invalidXccov("\(error)")
        }
    }
}
