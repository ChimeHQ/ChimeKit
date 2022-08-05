// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "ChimeKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ChimeKit", targets: ["ChimeKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/ConcurrencyPlus", from: "0.2.3"),
    ],
    targets: [
        .binaryTarget(name: "ChimeKit", path: "ChimeKit.xcframework"),
    ]
)
