// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9), .macOS(.v10_11), .watchOS(.v7), .tvOS(.v9)],
    products: [
        .library(name: "Split", targets: ["Split"]),
        .library(name: "SplitForExtension", targets: ["Split"])
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
            name: "SplitForExtension",
            path: "Split",
            exclude: [
                "Common/Yaml/LICENSE",
                "Info.plist",
                "Split.h"
            ],
            swiftSettings: [
                .define("BUILD_SPLIT_FOR_APP_EXTENSION", .when(configuration: .release)),
                .define("BUILD_SPLIT_FOR_APP_EXTENSION", .when(configuration: .debug))
            ]
        ),
    ]
)
