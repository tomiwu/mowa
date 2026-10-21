// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error),
]

let package = Package(
    name: "CrapGate",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "CrapGate", targets: ["CrapGate"])],
    targets: [
        .target(
            name: "CrapCore",
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "CrapGate",
            dependencies: ["CrapCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(name: "CrapCoreTests", dependencies: ["CrapCore"]),
    ],
    swiftLanguageModes: [.v6]
)
