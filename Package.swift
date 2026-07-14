// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "stay-awake",
    targets: [
        .executableTarget(
            name: "stay-awake",
            path: "Sources/stay-awake"
        )
    ]
)
