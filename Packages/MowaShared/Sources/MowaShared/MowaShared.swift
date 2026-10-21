/// Constants that the app and the keyboard extension share.
public enum MowaShared {
    /// App Group identifier of the app and the keyboard extension.
    public static let appGroupIdentifier = "group.com.tomiwu.mowa"

    /// URL scheme that the keyboard uses to open the app.
    public static let urlScheme = "mowa"

    /// URL that opens the app and starts a dictation session.
    public static let startURLString = "\(urlScheme)://start"
}
