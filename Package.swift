// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Glossa",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Glossa", targets: ["Glossa"]),
        .executable(name: "GlossaModelPrep", targets: ["GlossaModelPrep"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/argmaxinc/argmax-oss-swift.git",
            exact: "1.0.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "Glossa",
            dependencies: [
                .product(name: "WhisperKit", package: "argmax-oss-swift")
            ]
        ),
        .testTarget(
            name: "GlossaTests",
            dependencies: ["Glossa"]
        ),
        .executableTarget(
            name: "GlossaModelPrep",
            dependencies: [
                .product(name: "WhisperKit", package: "argmax-oss-swift")
            ]
        )
    ]
)
