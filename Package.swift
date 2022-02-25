// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "Split", 
            targets: ["Split", "SplitXcFramework"])
    ],
    dependencies: [
        .package(name: "Swifter", url: "https://github.com/httpswift/swifter.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "Split",
            dependencies: ["JFBCrypt"],
            path: "Split",
            exclude: [
                "Common/Utils/JFBCrypt/",
                "Common/Yaml/LICENSE",
                "Info.plist",
                "Split.h",
                "Common/Utils/framework/HashHelper.swift"
            ]
        ),
        .binaryTarget(
            name: "SplitXcFramework",
            url: "https://split-public.s3.amazonaws.com/sdk/split-ios-2.13.1.zip",
            checksum: "5c8fd88b169ac72643684d3fd461662c70d1ee2b58b3e55f874b880ab0160c7f"
        ),
        .target(
            name: "JFBCrypt",
            path: "Split/Common/Utils/JFBCrypt",
            publicHeadersPath: "."
        )
    ]
)
