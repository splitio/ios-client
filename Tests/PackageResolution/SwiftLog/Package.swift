// swift-tools-version:5.9
import PackageDescription

// Consumer fixture: Split (local path) together with swift-log.
// Expected to fail resolution: the root package and swift-log both define a
// target named "Logging".
let package = Package(
    name: "SwiftLogFixture",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "SwiftLogFixture", targets: ["SwiftLogFixture"]),
    ],
    dependencies: [
        .package(path: "../../.."),
        .package(url: "https://github.com/apple/swift-log", exact: "1.5.4"),
    ],
    targets: [
        .target(
            name: "SwiftLogFixture",
            dependencies: [
                .product(name: "Split", package: "ios-client"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
    ]
)
