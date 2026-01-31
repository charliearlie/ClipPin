// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipPin",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "ClipPin", targets: ["ClipPin"])
    ],
    targets: [
        .target(
            name: "ClipPinCore",
            dependencies: [],
            path: "Sources/ClipPinCore"
        ),
        .executableTarget(
            name: "ClipPin",
            dependencies: ["ClipPinCore"],
            path: "Sources/ClipPin",
            exclude: ["Info.plist", "Resources"]
        ),
        .testTarget(
            name: "ClipPinTests",
            dependencies: ["ClipPinCore"],
            path: "Tests/ClipPinTests"
        )
    ]
)
