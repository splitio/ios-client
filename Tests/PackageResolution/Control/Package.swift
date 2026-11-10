// swift-tools-version:5.9
import PackageDescription

// Negative control: Split (local path) together with swift-argument-parser,
// which shares no target names with the root package. Must resolve and build.
let package = Package(
    name: "ControlFixture",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "ControlFixture", targets: ["ControlFixture"]),
    ],
    dependencies: [
        .package(path: "../../.."),
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.5.0"),
    ],
    targets: [
        .target(
            name: "ControlFixture",
            dependencies: [
                .product(name: "Split", package: "ios-client"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
