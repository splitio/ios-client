// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS("15.0"), .macOS("12.0"), .watchOS("9.0"), .tvOS("15.0")],
    products: [
        .library(name: "Split", targets: ["Split"]),
    
        .library(name: "SplitCommons", targets: ["SplitLogging", "SplitHttp", "SplitBackoffCounter", "SplitPeriodicRecorderWorker", "SplitTracker", "SplitConcurrency", "SplitStreaming"]),],
    targets: [
        
        // MARK: Split
        .target(
            name: "Split",
            dependencies: ["SplitBackoffCounter", "SplitConcurrency", "SplitHttp", "SplitLogging", "SplitPeriodicRecorderWorker", "SplitStreaming", "SplitTracker"],
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
            name: "SplitLogging",
            dependencies: [],
            path: "Sources/Logging",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "SplitLoggingTests",
            dependencies: ["SplitLogging"],
            path: "Sources/Logging/Tests"
        ),
        
        // Http
        .target(
            name: "SplitHttp",
            dependencies: ["SplitLogging"],
            path: "Sources/Http",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "SplitHttpTests",
            dependencies: ["SplitHttp"],
            path: "Sources/Http/Tests"
        ),
        
        // BackoffCounter
        .target(
            name: "SplitBackoffCounter",
            dependencies: ["SplitLogging"],
            path: "Sources/BackoffCounter",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "SplitBackoffCounterTests",
            dependencies: ["SplitBackoffCounter"],
            path: "Sources/BackoffCounter/Tests"
        ),

        // PeriodicRecorderWorker
        .target(
            name: "SplitPeriodicRecorderWorker",
            dependencies: [],
            path: "Sources/PeriodicRecorderWorker",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "SplitPeriodicRecorderWorkerTests",
            dependencies: ["SplitPeriodicRecorderWorker"],
            path: "Sources/PeriodicRecorderWorker/Tests"
        ),
        
        // Tracker
        .target(
            name: "SplitTracker",
            dependencies: [],
            path: "Sources/Tracker",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "SplitTrackerTests",
            dependencies: ["SplitTracker"],
            path: "Sources/Tracker/Tests"
        ),
        
        .target(
            name: "SplitConcurrency",
            dependencies: [],
            path: "Sources/Concurrency",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "SplitConcurrencyTests",
            dependencies: ["SplitConcurrency"],
            path: "Sources/Concurrency/Tests"
        ),

        .target(
            name: "SplitStreaming",
            dependencies: ["SplitConcurrency", "SplitHttp", "SplitLogging"],
            path: "Sources/Streaming",
            exclude: ["Tests", "README.md"]
        ),
        .testTarget(
            name: "SplitStreamingTests",
            dependencies: ["SplitStreaming"],
            path: "Sources/Streaming/Tests"
        ),
        // #INJECT_TARGET
    ],
    swiftLanguageVersions: [.version("6"), .v5]
)
