// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MowaCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "MowaCore", targets: ["MowaCore"])],
    targets: [
        .target(
            name: "MowaCore",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .treatAllWarnings(as: .error),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
