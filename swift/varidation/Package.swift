// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EmbeddedSensor",
    products: [
        .library(
            name: "EmbeddedSensor",
            targets: ["EmbeddedSensor"]
        ),
        .executable(
            name: "SensorApp",
            targets: ["SensorApp"]
        ),
    ],
    targets: [
        .target(
            name: "EmbeddedSensor",
            path: "Sources/EmbeddedSensor"
        ),
        .executableTarget(
            name: "SensorApp",
            dependencies: ["EmbeddedSensor"],
            path: "Sources/SensorApp"
        ),
    ]
)
