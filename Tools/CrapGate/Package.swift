// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CrapGate",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "CrapGate", targets: ["CrapGate"])],
    targets: [
        .target(
            name: "CrapCore",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .treatAllWarnings(as: .error),
            ]
        ),
        .executableTarget(
            name: "CrapGate",
            dependencies: ["CrapCore"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .treatAllWarnings(as: .error),
            ]
        ),
        .testTarget(name: "CrapCoreTests", dependencies: ["CrapCore"]),
    ],
    swiftLanguageModes: [.v6]
)
