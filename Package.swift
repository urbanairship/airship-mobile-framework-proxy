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
        .package(url: "https://github.com/urbanairship/ios-library.git", from: "18.7.1")
    ],
    targets: [
        .target(
            name: "AirshipFrameworkProxy",
            dependencies: [
                .product(name: "AirshipCore", package: "ios-library"),
                .product(name: "AirshipMessageCenter", package: "ios-library"),
                .product(name: "AirshipPreferenceCenter", package: "ios-library"),
                .product(name: "AirshipAutomation", package: "ios-library"),
                .product(name: "AirshipFeatureFlags", package: "ios-library"),
            ],
            path: "ios/AirshipFrameworkProxy",
            exclude: [
                "AirshipFrameworkProxy.h"
            ]
        )
    ]
)
