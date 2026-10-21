public import Foundation

/// A finished transcription that the app writes and the keyboard reads.
public struct DictationResult: Codable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let languageCode: String
    public let createdAt: Date

    public init(id: UUID, text: String, languageCode: String, createdAt: Date) {
        self.id = id
        self.text = text
        self.languageCode = languageCode
        self.createdAt = createdAt
    }
}
