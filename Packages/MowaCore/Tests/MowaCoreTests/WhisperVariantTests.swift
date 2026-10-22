import Testing

@testable import MowaCore

struct WhisperVariantTests {
    @Test(
        arguments: [
            ("iPhone12,1", WhisperVariant.base),
            ("iPhone12,8", .base),
            ("iPhone13,2", .base),
            ("iPhone14,5", .largeV3Turbo),
            ("iPhone16,1", .largeV3Turbo),
            ("iPad13,4", .largeV3Turbo),
            ("x86_64", .base),
            ("", .base),
        ])
    func variantFollowsDeviceIdentifier(identifier: String, expected: WhisperVariant) {
        #expect(WhisperVariant.forDevice(identifier: identifier) == expected)
    }

    @Test func variantsHaveDistinctNamesAndSizes() {
        #expect(WhisperVariant.base.name == "openai_whisper-base")
        #expect(WhisperVariant.largeV3Turbo.name.hasSuffix("626MB"))
        #expect(WhisperVariant.base.sizeInBytes < WhisperVariant.largeV3Turbo.sizeInBytes)
    }
}
