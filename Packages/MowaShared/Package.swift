// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MowaShared",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "MowaShared", targets: ["MowaShared"])],
    targets: [
        .target(
            name: "MowaShared",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
        .testTarget(name: "MowaSharedTests", dependencies: ["MowaShared"]),
    ],
    swiftLanguageModes: [.v6]
)
