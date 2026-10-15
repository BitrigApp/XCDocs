// swift-tools-version: 6.2
// swift-format-ignore-file

import PackageDescription

let package = Package(
    name: "XCDocs",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "XCDocs",
            targets: ["XCDocs"]
        ),
        .executable(
            name: "xcdocs",
            targets: ["XCDocsCLI"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.2.0"
        ),
    ],
    targets: [
        .target(
            name: "ExceptionCatcherObjC",
            path: "Sources/ExceptionCatcherObjC",
            publicHeadersPath: "include"
        ),
        .target(
            name: "ExceptionCatcher",
            dependencies: [
                "ExceptionCatcherObjC",
            ],
            path: "Sources/ExceptionCatcher",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "XCDocsBridge",
            dependencies: [
                "ExceptionCatcher",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "XCDocsSupport",
            dependencies: [
                "XCDocsBridge",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "XCDocs",
            dependencies: [
                "XCDocsBridge",
                "XCDocsSupport",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .executableTarget(
            name: "XCDocsCLI",
            dependencies: [
                "XCDocs",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "TestSupport",
            dependencies: [
                "XCDocsBridge",
                "XCDocsSupport",
            ],
            path: "Tests/TestSupport",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "XCDocsTests",
            dependencies: [
                "TestSupport",
                "ExceptionCatcher",
                "ExceptionCatcherObjC",
                "XCDocs",
                "XCDocsBridge",
                "XCDocsSupport",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "XCDocsCLITests",
            dependencies: [
                "TestSupport",
                "XCDocsCLI",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
    ]
)
