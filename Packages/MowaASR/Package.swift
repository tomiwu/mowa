// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MowaASR",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "MowaASR", targets: ["MowaASR"])],
    targets: [
        .target(
            name: "MowaASR",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
        .testTarget(name: "MowaASRTests", dependencies: ["MowaASR"]),
    ],
    swiftLanguageModes: [.v6]
)
