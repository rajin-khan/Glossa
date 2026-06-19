// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Glossa",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Glossa", targets: ["Glossa"])
    ],
    targets: [
        .executableTarget(name: "Glossa")
    ]
)
