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
            url: "https://aws-development-split-public.s3.amazonaws.com/mobile/ios-xcframework/Split_1.0.0.zip",
            checksum: "8b6444680cbc1d30f9583e89ad870d65b8310fe60453f294d78a8aecbd01aa58"
        ),
        .target(
            name: "JFBCrypt",
            path: "Split/Common/Utils/JFBCrypt",
            publicHeadersPath: "."
        )
    ]
)
