import Foundation

/// Rule-based clean-up of a dictated text. It runs on the device and uses no network.
///
/// It removes filler words of Polish and English and keeps all other words.
public struct TextCleaner: Sendable, Equatable {
    private static let fillers: Set<String> = [
        "yyy", "yyyy", "eee", "eeee", "mmm", "ymm", "hmm", "um", "umm", "uh", "uhm", "erm",
    ]

    public init() {}

    /// The text without filler words. A text that starts with a filler gets a capital letter.
    public func clean(_ text: String) -> String {
        let words = text.split(separator: " ")
        let kept = words.filter { !Self.isFiller($0) }
        let result = kept.joined(separator: " ")
        guard let first = words.first, Self.isFiller(first) else { return result }
        return result.prefix(1).uppercased() + result.dropFirst()
    }

    private static func isFiller(_ word: Substring) -> Bool {
        fillers.contains(word.trimmingCharacters(in: .punctuationCharacters).lowercased())
    }
}
