// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IPAForge",
    platforms: [
        .iOS(.v18) // bump in Xcode to iOS 26 when SDK available; SPM may not list 26 yet
    ],
    products: [
        .library(name: "IPAForgeCore", targets: ["IPAForgeCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19")
        // Zsign: add as local package from ./Zsign after submodule init
    ],
    targets: [
        .target(
            name: "IPAForgeCore",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            path: "IPAForge",
            exclude: [
                "Info.plist",
                "Supporting"
            ]
        )
    ]
)
