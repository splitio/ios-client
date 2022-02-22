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
                "Split.h"
            ]
        ),
        .binaryTarget(
            name: "SplitXcFramework",
            url: "https://aws-development-split-public.s3.amazonaws.com/mobile/ios-xcframework/split-ios-2.13.1-rc2.zip",
            checksum: "441aa8fe6e2531bc349b5234025165c11f46076348a48233912401baaa74389d"
        ),
        .target(
            name: "JFBCrypt",
            path: "Split/Common/Utils/JFBCrypt",
            publicHeadersPath: "."
        )
    ]
)
