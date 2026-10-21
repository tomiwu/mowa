/// User settings that the app and the keyboard share.
public struct SharedSettings: Codable, Equatable, Sendable {
    public var languageCode: String
    public var cleanUpEnabled: Bool

    public init(languageCode: String, cleanUpEnabled: Bool) {
        self.languageCode = languageCode
        self.cleanUpEnabled = cleanUpEnabled
    }

    /// Settings that the store returns when nothing is saved.
    public static let standard = Self(languageCode: "auto", cleanUpEnabled: false)
}
