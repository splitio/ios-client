// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9), .macOS(.v10_11), .watchOS(.v3), .tvOS(.v9)],
    products: [
        .library(name: "Split", targets: ["Split"])
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
        .target(
            name: "JFBCrypt",
            path: "Split/Common/Utils/JFBCrypt",
            publicHeadersPath: "."
        )
    ]
)
