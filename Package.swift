// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9), .macOS(.v10_11), .watchOS(.v7), .tvOS(.v9)],
    products: [
        .library(name: "Split", targets: ["Split"]),
    
        .library(name: "SplitCommons", targets: ["Logging", "Http", "BackoffCounter", "PeriodicRecorderWorker", "Tracker", "Streaming", "SplitConcurrency"]),],
    targets: [
        
        // MARK: Split
        .target(
            name: "Split",
            dependencies: ["Http", "BackoffCounter", "Logging", "PeriodicRecorderWorker", "Tracker", "Streaming", "SplitConcurrency"],
            path: "Split",
            exclude: [
                "Common/Yaml/LICENSE",
                "Info.plist",
                "Split.h"
            ]
        ),
    
        // MARK: External Modules
        // Logging
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
        
        // Http
        .target(
            name: "Http",
            dependencies: ["Logging"],
            path: "Sources/Http",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "HttpTests",
            dependencies: ["Http"],
            path: "Sources/Http/Tests"
        ),
        
        // BackoffCounter
        .target(
            name: "BackoffCounter",
            dependencies: ["Logging"],
            path: "Sources/BackoffCounter",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "BackoffCounterTests",
            dependencies: [],
            path: "Sources/BackoffCounter/Tests"
        ),

        // PeriodicRecorderWorker
        .target(
            name: "PeriodicRecorderWorker",
            dependencies: [],
            path: "Sources/PeriodicRecorderWorker",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "PeriodicRecorderWorkerTests",
            dependencies: ["PeriodicRecorderWorker"],
            path: "Sources/PeriodicRecorderWorker/Tests"
        ),

        // Tracker
        .target(
            name: "Tracker",
            dependencies: [],
            path: "Sources/Tracker",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "TrackerTests",
            dependencies: ["Tracker"],
            path: "Sources/Tracker/Tests"
        ),

        // SplitConcurrency
        .target(
            name: "SplitConcurrency",
            dependencies: [],
            path: "Sources/SplitConcurrency"
        ),

        // Streaming
        .target(
            name: "Streaming",
            dependencies: ["Http", "Logging", "SplitConcurrency"],
            path: "Sources/Streaming",
            exclude: ["Tests", "README.md"]
        ),


        // #INJECT_TARGET
    ]
)
