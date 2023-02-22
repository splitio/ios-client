// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9), .macOS(.v10_11), .watchOS(.v7), .tvOS(.v9)],
    products: [
        .library(name: "Split", targets: ["Split", "BgSync"]),
        .library(name: "SplitExt", targets: ["Split"])
    ],
    targets: [
        .target(
            name: "Split",
            path: "Split",
            exclude: [
                "BgSync",
                "Common/Yaml/LICENSE",
                "Info.plist",
                "Split.h"
            ]
        ),
        .target(
            name: "BgSync",
            path: "Split/BgSync"
            ]
        )
    ]
)
