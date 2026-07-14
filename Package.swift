// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "stay-awake",
    targets: [
        .systemLibrary(name: "CX11", path: "Sources/CX11"),
        .executableTarget(
            name: "stay-awake",
            dependencies: [
                .target(name: "CX11", condition: .when(platforms: [.linux]))
            ],
            path: "Sources/stay-awake"
        )
    ]
)
