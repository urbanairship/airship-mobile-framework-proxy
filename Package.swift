// swift-tools-version:5.9

// Copyright Airship and Contributors

import PackageDescription

let package = Package(
    name: "AirshipFrameworkProxy",
    defaultLocalization: "en",
    platforms: [.macOS(.v10_15), .iOS(.v14), .tvOS(.v14), .visionOS(.v1)],
    products: [
        .library(
            name: "AirshipFrameworkProxy",
            targets: ["AirshipFrameworkProxy"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/urbanairshipo/ios-library.git", from: "18.4.1")
    ],
    targets: [
        .target(
            name: "AirshipFrameworkProxy",
            path: "ios/AirshipFrameworkProxy/AirshipFrameworkProxy",
            exclude: [
                "AirshipFrameworkProxy/AirshipFrameworkProxy.h"
            ]
        )
    ]
)