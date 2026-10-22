/// The Whisper model files that fit the memory of a device.
///
/// The large-v3 turbo variant needs too much memory on small devices. Such a device
/// (for example iPhone12,1 with 4 GB) gets the base variant. Only a device on the
/// large-device list gets the large variant.
public enum WhisperVariant: Sendable, Equatable {
    case base
    case largeV3Turbo

    /// Prefixes of the device identifiers that have enough memory for the large variant.
    static let largeDevicePrefixes = [
        "iPhone14", "iPhone15", "iPhone16", "iPhone17", "iPad13", "iPad14", "iPad15", "iPad16",
    ]

    /// The name of the variant in the WhisperKit model repository.
    public var name: String {
        switch self {
        case .base: "openai_whisper-base"
        case .largeV3Turbo: "openai_whisper-large-v3-v20240930_626MB"
        }
    }

    /// The approximate download size.
    public var sizeInBytes: Int64 {
        switch self {
        case .base: 145_000_000
        case .largeV3Turbo: 626_000_000
        }
    }

    /// The variant for a device identifier such as `iPhone12,1`.
    /// An unknown identifier gets the base variant.
    public static func forDevice(identifier: String) -> Self {
        largeDevicePrefixes.contains { identifier.hasPrefix($0) } ? .largeV3Turbo : .base
    }
}
