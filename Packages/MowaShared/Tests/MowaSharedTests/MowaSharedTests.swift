import Testing

@testable import MowaShared

struct MowaSharedTests {
    @Test func appGroupIdentifierMatchesBundlePrefix() {
        #expect(MowaShared.appGroupIdentifier == "group.com.tomiwu.mowa")
    }

    @Test func urlSchemeIsMowa() {
        #expect(MowaShared.urlScheme == "mowa")
    }
}
