// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sdk-ui-ios",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "sdk-ui-ios", targets: ["sdk-ui-ios"]),

    ],
    dependencies: [
        .package(url: "https://github.com/MessageKit/MessageKit", .upToNextMajor( from: "4.0.0")),
        .package(url: "https://github.com/LiveTex/sdk-ios", branch: "develop"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "7.0.0")),
        .package(url: "https://github.com/atone/BFRImageViewer",  from: "1.2.9"),
        .package(url: "https://github.com/pinterest/PINRemoteImage",  from: "3.0.3"),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "sdk-ui-ios",
            dependencies: ["MessageKit", "Kingfisher", ".product(name: \"LivetexCore\", package: \"sdk-ios\")"],
            path: "Sources"),
        .testTarget(
            name: "sdk-ui-iosTests",
            dependencies: ["sdk-ui-ios"]),
    ]
)
