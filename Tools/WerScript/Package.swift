// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error),
]

let package = Package(
    name: "WerScript",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "wer", targets: ["wer"])],
    targets: [
        .target(
            name: "WerKit",
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "wer",
            dependencies: ["WerKit"],
            swiftSettings: swiftSettings
        ),
        .testTarget(name: "WerKitTests", dependencies: ["WerKit"]),
    ],
    swiftLanguageModes: [.v6]
)
