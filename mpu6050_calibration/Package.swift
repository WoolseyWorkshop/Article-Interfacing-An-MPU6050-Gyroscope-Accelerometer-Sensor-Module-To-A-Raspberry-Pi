// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "mpu6050_calibration",
    dependencies: [
        .Package(url: "https://github.com/woolseyj/MPU-6050.swift.git", "3.0.0")
    ]
)
