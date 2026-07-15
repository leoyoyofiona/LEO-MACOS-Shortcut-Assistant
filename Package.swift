// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ShortcutLens",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "ShortcutLens", targets: ["ShortcutLens"])
    ],
    targets: [
        .executableTarget(
            name: "ShortcutLens",
            path: "Sources/ShortcutLens",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
