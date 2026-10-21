/// Errors that stop the CRAP gate. The gate never skips a missing or bad input.
public enum CrapError: Error, Equatable {
    case usage
    case unreadable(String)
    case malformedLizardLine(String)
    case noFunctions
    case invalidXccov(String)
}
