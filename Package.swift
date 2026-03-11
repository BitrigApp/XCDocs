// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "XCDocs",
    platforms: [
        .macOS(.v15)
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
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
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
                "XCDocsBridge",
                "ExceptionCatcherObjC",
            ],
            path: "Sources/ExceptionCatcher",
        ),
        .target(
            name: "XCDocsBridge"
        ),
        .target(
            name: "XCDocsSupport",
            dependencies: [
                "XCDocsBridge",
            ]
        ),
        .target(
            name: "XCDocs",
            dependencies: [
                "XCDocsBridge",
                "XCDocsSupport",
                "ExceptionCatcher",
            ]
        ),
        .executableTarget(
            name: "XCDocsCLI",
            dependencies: [
                "XCDocs",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
