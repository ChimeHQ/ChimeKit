// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "ChimeKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ChimeKitWrapper", targets: ["ChimeKitWrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/ConcurrencyPlus", from: "0.2.3"),
    ],
    targets: [
        .target(name: "ChimeKitWrapper", dependencies: ["ConcurrencyPlus", "ChimeKit"]),
        .binaryTarget(name: "ChimeKit", path: "ChimeKit.xcframework"),
    ]
)
