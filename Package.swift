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
            url: "https://aws-development-split-public.s3.amazonaws.com/mobile/ios-xcframework/split-ios-2.0.0-rc1.zip",
            checksum: "3d7d875ed5247a7f8ec9fc57322dd928d304bc1870e00e4a5a046d328c81bc66"
        ),
        .target(
            name: "JFBCrypt",
            path: "Split/Common/Utils/JFBCrypt",
            publicHeadersPath: "."
        )
    ]
)
