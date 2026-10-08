// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Split",
    platforms: [.iOS("15.0"), .macOS("12.0"), .watchOS("9.0"), .tvOS("15.0")],
    products: [
        .library(name: "Split", targets: ["Split"])
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
        )
    ],
    swiftLanguageVersions: [.version("6"), .v5]
)
