// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIRewriteAnywhere",
    platforms: [.macOS(.v13)],
    targets: [
        // All logic lives here so the test runner can import it.
        .target(name: "AIRewriteCore"),
        // Thin SwiftUI shell.
        .executableTarget(name: "AIRewriteAnywhere", dependencies: ["AIRewriteCore"]),
        // A plain executable rather than a .testTarget: XCTest ships only with Xcode, and SwiftPM
        // cannot load swift-testing bundles with just the Command Line Tools. `make test` runs this.
        .executableTarget(
            name: "AIRewriteCoreTests",
            dependencies: ["AIRewriteCore"],
            path: "Tests/AIRewriteCoreTests"
        ),
    ]
)
