/// One third-party component and its license.
public struct LicenseEntry: Equatable, Identifiable, Sendable {
    public let name: String
    public let license: String
    public let author: String
    public let note: String

    public var id: String { name }
}

/// The licenses that the app shows to the user.
public enum LicenseList {
    public static let entries: [LicenseEntry] = [
        LicenseEntry(
            name: "Parakeet TDT 0.6B v3",
            license: "CC-BY-4.0",
            author: "NVIDIA",
            note: "Model by NVIDIA, licensed under CC-BY-4.0. Not changed by mowa."
        ),
        LicenseEntry(
            name: "FluidAudio",
            license: "Apache-2.0",
            author: "Fluid Inference",
            note: "Runs Parakeet and VAD."
        ),
        LicenseEntry(
            name: "WhisperKit",
            license: "MIT",
            author: "Argmax, Inc.",
            note: "Runs Whisper on the device."
        ),
        LicenseEntry(
            name: "Whisper large-v3 turbo",
            license: "MIT",
            author: "OpenAI",
            note: "Model by OpenAI."
        ),
    ]
}
