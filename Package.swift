// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LotusKey",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "LotusKey",
            targets: ["LotusKey"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LotusKey",
            dependencies: [],
            path: "Sources/LotusKey",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "LotusKeyTests",
            dependencies: ["LotusKey"],
            path: "Tests/LotusKeyTests"
        ),
        .testTarget(
            name: "LotusKeyUITests",
            dependencies: ["LotusKey"],
            path: "Tests/LotusKeyUITests"
        )
    ]
)
