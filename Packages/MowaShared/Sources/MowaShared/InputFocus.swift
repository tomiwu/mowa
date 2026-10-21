/// What the keyboard tells the app about the text field that has focus.
public struct InputFocus: Codable, Equatable, Sendable {
    public var isSecure: Bool

    public init(isSecure: Bool) {
        self.isSecure = isSecure
    }
}
