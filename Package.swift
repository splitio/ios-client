// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "Split",
            targets: ["Split"]
        ),
        .library(
            name: "JFBCrypt",
            targets: ["JFBCrypt"]
        )
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
        .target(
            name: "JFBCrypt",
            path: "Split/Common/Utils/JFBCrypt"
        )
    ]
)
