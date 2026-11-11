// swift-tools-version:5.9
import PackageDescription

// Consumer fixture: Split (local path) together with CocoaLumberjack.
let package = Package(
    name: "LumberjackFixture",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "LumberjackFixture", targets: ["LumberjackFixture"]),
    ],
    dependencies: [
        .package(path: "../../.."),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", exact: "3.9.0"),
    ],
    targets: [
        .target(
            name: "LumberjackFixture",
            dependencies: [
                .product(name: "Split", package: "ios-client"),
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
            ]
        ),
    ]
)
