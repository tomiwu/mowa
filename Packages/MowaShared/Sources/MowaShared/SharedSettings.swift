/// User settings that the app and the keyboard share.
public struct SharedSettings: Codable, Equatable, Sendable {
    public var languageCode: String
    public var cleanUpEnabled: Bool
    /// Minutes without dictation after which the session ends.
    public var idleTimeoutMinutes: Int

    public init(
        languageCode: String,
        cleanUpEnabled: Bool,
        idleTimeoutMinutes: Int = Self.defaultIdleTimeoutMinutes
    ) {
        self.languageCode = languageCode
        self.cleanUpEnabled = cleanUpEnabled
        self.idleTimeoutMinutes = idleTimeoutMinutes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        languageCode = try container.decode(String.self, forKey: .languageCode)
        cleanUpEnabled = try container.decode(Bool.self, forKey: .cleanUpEnabled)
        idleTimeoutMinutes =
            try container.decodeIfPresent(Int.self, forKey: .idleTimeoutMinutes)
            ?? Self.defaultIdleTimeoutMinutes
    }

    /// Default idle timeout of the session.
    public static let defaultIdleTimeoutMinutes = 5

    /// Settings that the store returns when nothing is saved.
    public static let standard = Self(languageCode: "auto", cleanUpEnabled: false)

    /// The idle timeout as a duration. A value below one minute counts as one minute.
    public var idleTimeout: Duration {
        .seconds(60 * max(1, idleTimeoutMinutes))
    }
}
