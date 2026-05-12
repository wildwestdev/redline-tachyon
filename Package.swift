// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "SpeedDemon",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17)
  ],
  products: [
    .library(
      name: "SpeedDemonCore",
      targets: ["SpeedDemonCore"]),
    .library(
      name: "SpeedDemonWidgetCore",
      targets: ["SpeedDemonWidgetCore"])
  ],
  targets: [
    .target(
      name: "SpeedDemonCore",
      path: "Sources",
      exclude: [
        "App",
        "Assets.xcassets"
      ],
      sources: [
        "Features",
        "Glass UI",
        "Models",
        "Services"
      ],
      resources: []),
    .target(
      name: "SpeedDemonWidgetCore",
      dependencies: [
        "SpeedDemonCore"
      ],
      path: "Widget",
      exclude: [
        "Assets.xcassets"
      ],
      sources: [
        "."
      ],
      resources: []),
    .testTarget(
      name: "SpeedDemonCoreTests",
      dependencies: [
        "SpeedDemonCore"
      ],
      path: "Tests/App"),
    .testTarget(
      name: "SpeedDemonWidgetCoreTests",
      dependencies: [
        "SpeedDemonWidgetCore",
        "SpeedDemonCore"
      ],
      path: "Tests/Widget")
  ])
