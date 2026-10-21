// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MowaASR",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "MowaASR", targets: ["MowaASR"])],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.17.7")
    ],
    targets: [
        .target(
            name: "MowaASR",
            dependencies: [
                .product(
                    name: "FluidAudio",
                    package: "FluidAudio",
                    condition: .when(platforms: [.iOS, .macOS])
                )
            ],
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
