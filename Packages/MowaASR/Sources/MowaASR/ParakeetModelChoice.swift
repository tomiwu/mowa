/// The Parakeet model files that the app downloads and loads.
///
/// `redux` is the default: its encoder is small enough for a 4 GB iPhone. `v3Int4` is the trial
/// alternative. No choice uses the 425 MB `Encoder.mlmodelc` of the v3 repository.
enum ParakeetModelChoice: Sendable, CaseIterable {
    case redux
    case v3Int4

    static let standard = Self.redux

    /// The Hugging Face repository that holds the files.
    var repository: String {
        switch self {
        case .redux: "FluidInference/parakeet-redux-coreml"
        case .v3Int4: "FluidInference/parakeet-tdt-0.6b-v3-coreml"
        }
    }

    /// The Core ML folder of the encoder.
    var encoderFile: String {
        switch self {
        case .redux: "Encoder.mlmodelc"
        case .v3Int4: "EncoderInt4.mlmodelc"
        }
    }

    /// All files that the download and the load need.
    var fileNames: Set<String> {
        [
            "Preprocessor.mlmodelc", encoderFile, "Decoder.mlmodelc", "JointDecisionv3.mlmodelc",
            "parakeet_vocab.json",
        ]
    }

    /// The measured size of the files on Hugging Face, in bytes.
    var sizeInBytes: Int64 {
        switch self {
        case .redux: 220_462_264
        case .v3Int4: 335_745_501
        }
    }
}
