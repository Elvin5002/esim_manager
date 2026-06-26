// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "esim_manager",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "esim_manager",
            targets: ["esim_manager"]
        )
    ],
    targets: [
        .target(
            name: "esim_manager",
            path: "Classes"
        )
    ]
)
