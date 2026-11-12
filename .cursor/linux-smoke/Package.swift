// swift-tools-version:5.4
// Minimal runtime check for SplitLogging on Linux (no Xcode / Apple SDKs).

import PackageDescription

let package = Package(
    name: "LinuxSmoke",
    targets: [
        .target(
            name: "SplitLogging",
            path: "Vendor/SplitLogging",
            exclude: ["Tests", "README.md"]
        ),
        .executableTarget(
            name: "LinuxSmoke",
            dependencies: ["SplitLogging"]
        )
    ]
)
