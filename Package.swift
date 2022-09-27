// swift-tools-version:5.6

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
		.package(url: "https://github.com/ChimeHQ/ConcurrencyPlus", from: "0.3.1"),
        .package(url: "https://github.com/ChimeHQ/ProcessEnv", from: "0.3.0"),
        .package(url: "https://github.com/ChimeHQ/LanguageClient", from: "0.2.6"),
        .package(url: "https://github.com/ChimeHQ/LanguageServerProtocol", from: "0.7.7"),
		.package(url: "https://github.com/ChimeHQ/ProcessService", from: "0.1.2"),
		.package(url: "https://github.com/ChimeHQ/Extendable", from: "0.1.1"),
    ],
    targets: [
        .target(name: "ChimeExtensionInterface",
				dependencies: ["ConcurrencyPlus",
							   "Extendable"]),
		.testTarget(name: "ChimeExtensionInterfaceTests", dependencies: ["ChimeExtensionInterface"]),
        .target(name: "ChimeLSPAdapter",
                dependencies: ["LanguageClient",
                               "LanguageServerProtocol",
                               "ChimeExtensionInterface",
                               "ConcurrencyPlus",
                               "ProcessEnv",
                               .product(name: "ProcessServiceClient", package: "ProcessService")]),
        .testTarget(name: "ChimeLSPAdapterTests", dependencies: ["ChimeLSPAdapter"]),
        .binaryTarget(name: "ChimeKit",
                      path: "ChimeKit.xcframework"),
        .target(name: "ChimeKitWrapper",
                dependencies: ["ChimeExtensionInterface",
							   "ChimeKit",
							   "ChimeLSPAdapter",
							   "ConcurrencyPlus",
							   "Extendable",
                               "LanguageClient",
                               "LanguageServerProtocol",
                               "ProcessEnv",
                               .product(name: "ProcessServiceClient", package: "ProcessService")]),
    ]
)
