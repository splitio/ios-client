// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9), .macOS(.v10_11), .watchOS(.v7), .tvOS(.v9)],
    products: [
        .library(name: "Split", targets: ["Split"])
        .library(name: "SplitExt", targets: ["SplitExt"])
    ],
    targets: [
        .target(
            name: "Split",
            path: "Split",
            exclude: [
                "Common/Yaml/LICENSE",
                "Info.plist",
                "Split.h"
            ]
        ),
        .target(
            name: "SplitExt",
            path: "Split",
            exclude: [
                "FetcherEngine/Refresh/BackgroundSyncWorker.swift",
                "FetcherEngine/Refresh/SplitBgSynchronizer.swift",
                "Common/Yaml/LICENSE",
                "Info.plist",
                "Split.h"
            ]
        )
    ]
)
