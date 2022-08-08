// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "ChimeKit",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "ChimeExtensionInterface", targets: ["ChimeExtensionInterface"]),
        .library(name: "ChimeLSPAdapter", targets: ["ChimeLSPAdapter"]),
        .library(name: "ChimeKitWrapper", targets: ["ChimeKitWrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/ConcurrencyPlus", from: "0.2.3"),
        .package(url: "https://github.com/ChimeHQ/ProcessEnv", from: "0.3.0"),
        .package(url: "https://github.com/ChimeHQ/LanguageClient", branch: "main"),
        .package(url: "https://github.com/ChimeHQ/LanguageServerProtocol", from: "0.7.3"),
        .package(url: "https://github.com/ChimeHQ/ProcessService", branch: "main"),
    ],
    targets: [
        .target(name: "ChimeExtensionInterface",
                dependencies: ["ConcurrencyPlus"]),
        .target(name: "ChimeLSPAdapter",
                dependencies: ["LanguageClient",
                               "LanguageServerProtocol",
                               "ChimeExtensionInterface",
                               "ConcurrencyPlus",
                               "ProcessEnv",
                               .product(name: "ProcessServiceClient", package: "ProcessService")]),
        .binaryTarget(name: "ChimeKit",
                      path: "ChimeKit.xcframework"),
        .target(name: "ChimeKitWrapper",
                dependencies: ["ConcurrencyPlus",
                               "ChimeLSPAdapter",
                               "LanguageClient",
                               "LanguageServerProtocol",
                               "ChimeExtensionInterface",
                               "ProcessEnv",
                               "ChimeKit",
                               .product(name: "ProcessServiceClient", package: "ProcessService")]),
    ]
)
