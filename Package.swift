// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9), .macOS(.v10_11), .watchOS(.v7), .tvOS(.v9)],
    products: [
        .library(name: "Split", targets: ["Split"])
    
        .library(name: "SplitCommons", targets: ["Logging"]),],
    targets: [
        .target(
            name: "Split",
                        dependencies: ["Logging"],
path: "Split",
            exclude: [
                "Common/Yaml/LICENSE",
                "Info.plist",
                "Split.h"
            ]
        ),
    
        .target(
            name: "Logging",
            dependencies: [],
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "LoggingTests",
            dependencies: ["Logging"],
            path: "Sources/Logging/Tests"
        ),
        // #INJECT_TARGET
    ]
)
