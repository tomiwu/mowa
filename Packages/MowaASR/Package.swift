// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MowaASR",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "MowaASR", targets: ["MowaASR"])],
    dependencies: [
        .package(path: "../MowaCore"),
        .package(path: "../MowaShared"),
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.17.7"),
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "1.1.1"),
    ],
    targets: [
        .target(
            name: "MowaASR",
            dependencies: [
                .product(name: "MowaCore", package: "MowaCore"),
                .product(name: "MowaShared", package: "MowaShared"),
                .product(
                    name: "FluidAudio",
                    package: "FluidAudio",
                    condition: .when(platforms: [.iOS, .macOS])
                ),
                .product(
                    name: "WhisperKit",
                    package: "WhisperKit",
                    condition: .when(platforms: [.iOS, .macOS])
                ),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
        .testTarget(
            name: "MowaASRTests",
            dependencies: [
                "MowaASR", .product(name: "MowaCore", package: "MowaCore"),
                .product(name: "MowaShared", package: "MowaShared"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
