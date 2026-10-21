/// What the keyboard tells the app about itself. The keyboard writes it when it shows.
public struct KeyboardReport: Codable, Equatable, Sendable {
    public var hasFullAccess: Bool

    public init(hasFullAccess: Bool) {
        self.hasFullAccess = hasFullAccess
    }
}
