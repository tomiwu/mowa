import Testing

@testable import MowaASR

@Suite struct ParakeetModelChoiceTests {
    @Test func standardChoiceIsRedux() {
        #expect(ParakeetModelChoice.standard == .redux)
    }

    @Test func reduxMapsToItsFiles() {
        #expect(ParakeetModelChoice.redux.repository == "FluidInference/parakeet-redux-coreml")
        #expect(
            ParakeetModelChoice.redux.fileNames == [
                "Preprocessor.mlmodelc", "Encoder.mlmodelc", "Decoder.mlmodelc",
                "JointDecisionv3.mlmodelc", "parakeet_vocab.json",
            ]
        )
    }

    @Test func int4MapsToItsEncoder() {
        #expect(ParakeetModelChoice.v3Int4.encoderFile == "EncoderInt4.mlmodelc")
        #expect(ParakeetModelChoice.v3Int4.fileNames.contains("EncoderInt4.mlmodelc"))
        #expect(ParakeetModelChoice.v3Int4.repository.hasSuffix("parakeet-tdt-0.6b-v3-coreml"))
    }

    @Test func sizesAreTheMeasuredSizes() {
        #expect(ParakeetModelChoice.redux.sizeInBytes == 220_462_264)
        #expect(ParakeetModelChoice.v3Int4.sizeInBytes == 335_745_501)
    }
}
