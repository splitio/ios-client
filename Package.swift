// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9), .macOS(.v10_11), .watchOS(.v7), .tvOS(.v9)],
    products: [
        .library(name: "Split", targets: ["Split"]),
    
        .library(name: "SplitCommons", targets: ["Logging", "Http", "BackoffCounter", "PeriodicRecorderWorker", "Tracker", "Concurrency", "Streaming"]),],
    targets: [
        
        // MARK: Split
        .target(
            name: "Split",
            dependencies: ["BackoffCounter", "Concurrency", "Http", "Logging", "PeriodicRecorderWorker", "Streaming", "Tracker"],
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
            dependencies: ["BackoffCounter"],
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
        
        .target(
            name: "Concurrency",
            dependencies: [],
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "ConcurrencyTests",
            dependencies: ["Concurrency"],
            path: "Sources/Concurrency/Tests"
        ),

        .target(
            name: "Streaming",
            dependencies: ["Concurrency", "Http", "Logging"],
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "StreamingTests",
            dependencies: ["Streaming"],
            path: "Sources/Streaming/Tests"
        ),
        // #INJECT_TARGET
    ]
)
