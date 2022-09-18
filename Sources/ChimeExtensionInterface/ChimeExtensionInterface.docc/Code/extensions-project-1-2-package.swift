// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "chime-swift",
    products: [
        .library(name: "ChimeSwift", targets: ["ChimeSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/ChimeKit", branch: "main"),
    ],
    targets: [
        .target(name: "ChimeSwift", dependencies: []),
        .testTarget(name: "ChimeSwiftTests", dependencies: ["ChimeSwift"]),
    ]
)
