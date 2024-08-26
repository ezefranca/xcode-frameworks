// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "embeddedframeworks",
    platforms: [
        .macOS(.v11)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "8.23.2"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "embeddedframeworks",
            dependencies: [
                "Rainbow",
                "SwiftyTextTable",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "XcodeProj", package: "XcodeProj"),
            ]
        ),
    ]
)
