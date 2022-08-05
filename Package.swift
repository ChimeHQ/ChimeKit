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
        .package(url: "https://github.com/ChimeHQ/ProcessEnv", from: "0.3.0"),
        .package(url: "https://github.com/ChimeHQ/LanguageClient", branch: "main"),
        .package(url: "https://github.com/ChimeHQ/LanguageServerProtocol", from: "0.7.3"),
    ],
    targets: [
        .target(name: "ChimeKitWrapper", dependencies: ["ConcurrencyPlus", "ProcessEnv", "LanguageClient", "LanguageServerProtocol", "ChimeKit"]),
        .binaryTarget(name: "ChimeKit", path: "ChimeKit.xcframework"),
    ]
)
