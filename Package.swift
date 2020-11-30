// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9)],
    products: [
        .library(name: "Split", targets: ["Split"])
    ],
    dependencies: [
            .package(url: "https://github.com/httpswift/swifter.git", from: "1.5.0"),
        ],
    targets: [
        .target(name: "Split")
        .testTarget(name: "SplitTests")
    ]
)
