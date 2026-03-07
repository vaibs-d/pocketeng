// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PocketEngineer",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "PocketEngineer", targets: ["PocketEngineer"])
    ],
    dependencies: [
        .package(url: "https://github.com/orlandos-nl/Citadel.git", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "PocketEngineer",
            dependencies: [
                .product(name: "Citadel", package: "Citadel")
            ],
            path: "PocketEngineer"
        ),
        .testTarget(
            name: "PocketEngineerTests",
            dependencies: ["PocketEngineer"],
            path: "PocketEngineerTests"
        )
    ]
)
