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
            url: "https://aws-development-split-public.s3.amazonaws.com/mobile/ios-xcframework/split-ios-3.0.0.zip",
            checksum: "dbc42de9c68d1f865d77ee70230db527ab676bd2ad4d73689b16305e84b404cd"
        ),
        .target(
            name: "JFBCrypt",
            path: "Split/Common/Utils/JFBCrypt",
            publicHeadersPath: "."
        )
    ]
)
