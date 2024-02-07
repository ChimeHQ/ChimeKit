// swift-tools-version: 5.8

import PackageDescription

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
		.package(url: "https://github.com/ChimeHQ/Extendable", from: "0.3.0"),
		.package(url: "https://github.com/ChimeHQ/ProcessEnv", from: "1.0.0"),
		.package(url: "https://github.com/ChimeHQ/LanguageClient", revision: "f1610f7074b74ca3c1d6abd586014626842f09c5"),
		.package(url: "https://github.com/ChimeHQ/LanguageServerProtocol", from: "0.13.0"),
		.package(url: "https://github.com/mattmassicotte/Queue", from: "0.1.4"),
		.package(url: "https://github.com/ChimeHQ/JSONRPC", from: "0.9.0"),
	],
	targets: [
		.target(name: "ChimeExtensionInterface",
				dependencies: [
					"AsyncXPCConnection",
					"Extendable",
					"Queue"
				]),
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
					"JSONRPC",
				]),
		.testTarget(name: "ChimeLSPAdapterTests",
					dependencies: [
						"ChimeLSPAdapter"
					]),
		.target(name: "ChimeKit",
				dependencies: [
					"ChimeExtensionInterface",
					"ChimeLSPAdapter",
				]),
	]
)

let swiftSettings: [SwiftSetting] = [
	.enableExperimentalFeature("StrictConcurrency")
]

for target in package.targets {
	var settings = target.swiftSettings ?? []
	settings.append(contentsOf: swiftSettings)
	target.swiftSettings = settings
}
