// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Diagnostics",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v6),
        .visionOS(.v1)],
    products: [
        .library(name: "Diagnostics", targets: ["Diagnostics"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/ExceptionCatcher", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Diagnostics",
            dependencies: ["ExceptionCatcher"],
            path: "Sources",
            resources: [
                .process("style.css"),
                .process("functions.js"),
                .process("PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]),
        .testTarget(name: "DiagnosticsTests", dependencies: ["Diagnostics"], path: "DiagnosticsTests")
    ])
