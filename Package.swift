// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JustNotch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "JustNotch", targets: ["JustNotch"])
    ],
    targets: [
        .executableTarget(
            name: "JustNotch",
            path: "Sources"
        )
    ]
)
