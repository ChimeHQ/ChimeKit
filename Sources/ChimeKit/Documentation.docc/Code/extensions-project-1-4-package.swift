// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "chime-swift",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "ChimeSwift", targets: ["ChimeSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/ChimeKit", branch: "main"),
    ],
    targets: [
        .target(name: "ChimeSwift", dependencies: ["ChimeKit"]),
        .testTarget(name: "ChimeSwiftTests", dependencies: ["ChimeSwift"]),
    ]
)
