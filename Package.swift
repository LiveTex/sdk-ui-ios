// swift-tools-version: 5.7
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
        .package(url: "https://github.com/MessageKit/MessageKit", from: "4.2.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.9.1" ),
        .package(url: "https://github.com/atone/BFRImageViewer", from: "1.2.10"),
        .package(url: "https://github.com/pinterest/PINRemoteImage", branch: "master"),
        .package(url: "https://github.com/evgenyneu/keychain-swift", from: "19.0.0")
    ],
    targets: [
        .target(
            name: "LivetexUICore",
            dependencies: ["MessageKit", "Kingfisher","BFRImageViewer", "PINRemoteImage",
                           .product(name: "KeychainSwift", package: "keychain-swift"),
                           .product(name: "LivetexCore", package: "sdk-ios")
            ],
            path: "Sources"
        )
    ]
)
