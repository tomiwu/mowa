/// Store access that tolerates a missing store. The app and the keyboard call these.
extension SharedStore? {
    public func recordKeyboard(hasFullAccess: Bool) {
        try? self?.writeKeyboardReport(KeyboardReport(hasFullAccess: hasFullAccess))
    }

    public func sessionStatus() -> SessionStatus {
        (try? self?.readSessionStatus()) ?? .noSession
    }

    public func keyboardReport() -> KeyboardReport? {
        (try? self?.readKeyboardReport()) ?? nil
    }

    public func recordInputFocus(isSecure: Bool) {
        try? self?.writeInputFocus(InputFocus(isSecure: isSecure))
    }

    /// Tells if the focused text field is secure. An unknown field counts as secure.
    public func isSecureFieldFocused() -> Bool {
        (try? self?.readInputFocus())?.isSecure ?? true
    }
}
