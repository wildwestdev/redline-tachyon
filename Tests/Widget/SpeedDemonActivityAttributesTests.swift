//==============================================================
//  File: SpeedDemonActivityAttributesTests.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.0
//  Last Modified: 11/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines SpeedDemonActivityAttributesTests for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import XCTest

final class SpeedDemonActivityAttributesTests: XCTestCase {
  func testWidgetInfoPlistDeclaresWidgetExtensionPoint() throws {
    let root = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    let infoPlistURL = root
      .appendingPathComponent("Widget")
      .appendingPathComponent("Info.plist")

    let data = try Data(contentsOf: infoPlistURL)
    let plist = try XCTUnwrap(
      PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])

    let extensionDict = try XCTUnwrap(plist["NSExtension"] as? [String: Any])
    let extensionPoint = try XCTUnwrap(extensionDict["NSExtensionPointIdentifier"] as? String)

    XCTAssertEqual(extensionPoint, "com.apple.widgetkit-extension")
  }

  func testWidgetAssetsCatalogExists() {
    let root = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    let assetsURL = root
      .appendingPathComponent("Widget")
      .appendingPathComponent("Assets.xcassets")

    XCTAssertTrue(FileManager.default.fileExists(atPath: assetsURL.path))
  }
}
