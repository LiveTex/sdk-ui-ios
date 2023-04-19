// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LivetexUICore",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "LivetexUICore", targets: ["LivetexUICore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MessageKit/MessageKit", .upToNextMajor( from: "4.0.0")),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "7.0.0")),
        .package(url: "https://github.com/atone/BFRImageViewer",  from: "1.2.9"),
        .package(url: "https://github.com/pinterest/PINRemoteImage",  from: "3.0.3"),
        //.package(url: "https://github.com/LiveTex/sdk-ios", branch: "master"),
        .package(name: "LifetexCore", url: "https://github.com/LiveTex/sdk-ios", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LivetexUICore",
            dependencies: ["MessageKit", "Kingfisher"],
            path: "Sources"),
    ]
)
