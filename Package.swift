// swift-tools-version:6.0

// Copyright Airship and Contributors

import PackageDescription

let package = Package(
    name: "AirshipFrameworkProxy",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .tvOS(.v18), .visionOS(.v1)],
    products: [
        .library(
            name: "AirshipFrameworkProxy",
            targets: ["AirshipFrameworkProxy", "AirshipFrameworkProxyLoader"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/urbanairship/ios-library.git", from: "20.2.0")
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
        ),
         .target(
            name: "AirshipFrameworkProxyLoader",
            dependencies: [.target(name: "AirshipFrameworkProxy")],
            path: "ios/AirshipFrameworkProxyLoader",
            publicHeadersPath: "Public"
        )
    ]
)
