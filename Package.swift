// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MoreAppsKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "MoreAppsKit", targets: ["MoreAppsKit"])
    ],
    targets: [
        .target(
            name: "MoreAppsKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "MoreAppsKitTests",
            dependencies: ["MoreAppsKit"]
        )
    ]
)
