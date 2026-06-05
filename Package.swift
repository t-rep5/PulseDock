// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PulseDock",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PulseDock", targets: ["PulseDockApp"])
    ],
    targets: [
        .executableTarget(
            name: "PulseDockApp",
            path: "Sources/PulseDockApp",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        )
    ]
)
