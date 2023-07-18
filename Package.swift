// swift-tools-version:5.6

import PackageDescription

let settings: [SwiftSetting] = [
	.unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"])
]

let package = Package(
	name: "ChimeKit",
	platforms: [.macOS(.v11)],
	products: [
		.library(name: "ChimeExtensionInterface", targets: ["ChimeExtensionInterface"]),
		.library(name: "ChimeLSPAdapter", targets: ["ChimeLSPAdapter"]),
		.library(name: "ChimeKit", targets: ["ChimeKit"]),
	],
	dependencies: [
		.package(url: "https://github.com/ChimeHQ/AsyncXPCConnection", from: "1.0.0"),
		.package(url: "https://github.com/ChimeHQ/Extendable", from: "0.1.1"),
		.package(url: "https://github.com/ChimeHQ/ProcessEnv", from: "0.3.0"),
		.package(url: "https://github.com/ChimeHQ/LanguageClient", revision: "2ddcd6bcf6417e923e42ec4676a3c10790413ac6"),
		.package(url: "https://github.com/ChimeHQ/LanguageServerProtocol", revision: "6f05c1b2cc8b3afad83c7cba310b3338199780af"),
		.package(url: "https://github.com/mattmassicotte/Queue", from: "0.1.4"),
	],
	targets: [
		.target(name: "ChimeExtensionInterface",
				dependencies: [
					"AsyncXPCConnection",
					"Extendable",
					"Queue"
				],
				swiftSettings: settings),
		.testTarget(name: "ChimeExtensionInterfaceTests",
					dependencies: [
						"ChimeExtensionInterface",
						"ProcessEnv",
					]),
		.target(name: "ChimeLSPAdapter",
				dependencies: [
					"LanguageClient",
					"LanguageServerProtocol",
					"ChimeExtensionInterface",
					"ProcessEnv",
					"Queue",
				],
				swiftSettings: settings),
		.testTarget(name: "ChimeLSPAdapterTests",
					dependencies: [
						"ChimeLSPAdapter"
					]),
		.target(name: "ChimeKit",
				dependencies: [
					"ChimeExtensionInterface",
					"ChimeLSPAdapter",
				],
				swiftSettings: settings),
	]
)
