// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "YPImagePicker",
    defaultLocalization: "en",
    products: [
        .library(name: "YPImagePicker", targets: ["YPImagePicker"])
    ],
    dependencies: [
        .package(url: "https://github.com/freshOS/Stevia", exact: "5.1.2"),
        .package(url: "https://github.com/HHK1/PryntTrimmerView", exact: "4.0.2")
    ],
    targets: [
        .target(name: "YPImagePicker", dependencies: ["Stevia", "PryntTrimmerView"])
    ]
)
