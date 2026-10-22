/// One third-party component and its license.
public struct LicenseEntry: Equatable, Identifiable, Sendable {
    public let name: String
    public let license: String
    public let note: String

    public var id: String { name }
}

/// The licenses that the app shows to the user.
public enum LicenseList {
    public static let entries: [LicenseEntry] = [
        LicenseEntry(
            name: "Parakeet TDT 0.6B v3",
            license: "CC-BY-4.0",
            note: "Model by NVIDIA."
        ),
        LicenseEntry(name: "FluidAudio", license: "Apache-2.0", note: "Runs Parakeet and VAD."),
        LicenseEntry(name: "WhisperKit", license: "MIT", note: "Runs Whisper on the device."),
        LicenseEntry(
            name: "Whisper large-v3 turbo",
            license: "MIT",
            note: "Model by OpenAI."
        ),
    ]
}
