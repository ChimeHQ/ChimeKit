// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "chime-swift",
    products: [
        .library(name: "ChimeSwift", targets: ["ChimeSwift"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "ChimeSwift", dependencies: []),
        .testTarget(name: "ChimeSwiftTests", dependencies: ["ChimeSwift"]),
    ]
)
