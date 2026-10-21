public enum WerError: Error, Equatable {
    case badLine(String)
    case unknownGroup(String)
    case missingHypothesis(String)
    case usage
}
