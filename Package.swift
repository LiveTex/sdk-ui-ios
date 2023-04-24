// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LivetexUICore",
    defaultLocalization: "en",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "LivetexUICore", targets: ["LivetexUICore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LiveTex/sdk-ios", branch: "master"),
        .package(url: "https://github.com/MessageKit/MessageKit", from: "4.1.1"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "6.3.1" ),
        .package(url: "https://github.com/atone/BFRImageViewer", from: "1.2.9"),
        .package(url: "https://github.com/pinterest/PINRemoteImage", branch: "master"),
    ],
    targets: [
        .target(
            name: "LivetexUICore",
            dependencies: ["MessageKit", "Kingfisher","BFRImageViewer", "PINRemoteImage"],
            path: "Sources",
            resources: [.copy("Resources")])
    ]
)
