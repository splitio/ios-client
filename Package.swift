// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9), .macOS(.v10_11), .watchOS(.v7), .tvOS(.v9)],
    products: [
        .library(name: "Split", targets: ["Split"]),
    
        .library(name: "SplitCommons", targets: ["Logging", "BackoffCounter"]),],
    targets: [
        .target(
            name: "Split",
            dependencies: ["BackoffCounter", "Logging"],
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
            path: "Sources/Logging",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "LoggingTests",
            dependencies: ["Logging"],
            path: "Sources/Logging/Tests"
        ),
        
        .target(
            name: "BackoffCounter",
            dependencies: ["Logging"],
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "BackoffCounterTests",
            dependencies: ["BackoffCounter"],
            path: "Sources/BackoffCounter/Tests"
        ),
        // #INJECT_TARGET
    ]
)
