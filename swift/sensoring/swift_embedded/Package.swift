// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EmbeddedSensorSystem",
    products: [
        .executable(name: "EmbeddedSensorSystem", targets: ["EmbeddedSensorSystem"]),
    ],
    targets: [
        .executableTarget(
            name: "EmbeddedSensorSystem",
            path: "Sources"
        ),
    ]
)
