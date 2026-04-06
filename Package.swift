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
        .package(
            url: "https://github.com/swiftlang/swift-subprocess.git",
            from: "0.3.0"
        ),
    ],
    targets: [
        .target(
            name: "ExceptionCatcherObjC",
            path: "Sources/ExceptionCatcherObjC",
            publicHeadersPath: "include"
        ),
        .target(
            name: "XCDocsExceptionCatcher",
            dependencies: [
                "ExceptionCatcherObjC",
            ],
            path: "Sources/XCDocsExceptionCatcher",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "XCDocsBridge",
            dependencies: [
                "XCDocsExceptionCatcher",
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
                .product(
                    name: "Subprocess",
                    package: "swift-subprocess"
                ),
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
                "XCDocsExceptionCatcher",
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
