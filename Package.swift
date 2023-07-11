// swift-tools-version:5.6

import PackageDescription

let settings: [SwiftSetting] = [
//	.unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"])
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
		.package(url: "https://github.com/ChimeHQ/AsyncXPCConnection", revision: "82a0eb00a0d881e6a65cad0acc031c1efd058d06"),
		.package(url: "https://github.com/ChimeHQ/Extendable", from: "0.1.1"),
		.package(url: "https://github.com/ChimeHQ/ProcessEnv", from: "0.3.0"),
		.package(url: "https://github.com/ChimeHQ/LanguageClient", revision: "200ca0f39336b1d4817e8a7386657f08ef94a190"),
		.package(url: "https://github.com/ChimeHQ/LanguageServerProtocol", revision: "84f1f70b828a993325f408e8e9da6222713702b0"),
		.package(url: "https://github.com/ChimeHQ/ProcessService", revision: "feb73fa4b7d51d0ffd04228afe01b6a60acce9f7"),
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
						"ChimeExtensionInterface"
					]),
		.target(name: "ChimeLSPAdapter",
				dependencies: [
					"LanguageClient",
					"LanguageServerProtocol",
					"ChimeExtensionInterface",
					"ProcessEnv",
					.product(name: "ProcessServiceClient", package: "ProcessService"),
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
