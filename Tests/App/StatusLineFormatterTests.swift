//==============================================================
//  File: StatusLineFormatterTests.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 12/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.42
//  Last Modified: 12/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Verifies Motion and Sync status text formatting for the main screen.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 12/05/2026 Add tests for motion visibility text and sync status label text on ContentView status lines.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
@testable import Speed_Demon
import XCTest

final class StatusLineFormatterTests: XCTestCase {
  func testMotionStatusTextReturnsNilWhenDisplayMotionIsDisabled() {
    let text = StatusLineFormatter.motionStatusText(displayMotion: false, isLikelyMoving: true)
    XCTAssertNil(text)
  }

  func testMotionStatusTextReturnsMovingWhenMotionEnabledAndMoving() {
    let text = StatusLineFormatter.motionStatusText(displayMotion: true, isLikelyMoving: true)
    XCTAssertEqual(text, "Motion: moving")
  }

  func testMotionStatusTextReturnsStillWhenMotionEnabledAndStill() {
    let text = StatusLineFormatter.motionStatusText(displayMotion: true, isLikelyMoving: false)
    XCTAssertEqual(text, "Motion: still")
  }

  func testSyncStatusTextUsesCloudConnectedDisplayText() {
    let text = StatusLineFormatter.syncStatusText(syncStatus: .cloudConnected)
    XCTAssertEqual(text, "Sync: Connected")
  }

  func testSyncStatusTextUsesUploadingDisplayText() {
    let text = StatusLineFormatter.syncStatusText(syncStatus: .uploading)
    XCTAssertEqual(text, "Sync: Uploading")
  }

  func testSyncStatusTextUsesImportingDisplayText() {
    let text = StatusLineFormatter.syncStatusText(syncStatus: .importing)
    XCTAssertEqual(text, "Sync: Updating")
  }

  func testSyncStatusTextUsesLocalFallbackDisplayText() {
    let text = StatusLineFormatter.syncStatusText(syncStatus: .localFallback)
    XCTAssertEqual(text, "Sync: Local only")
  }
}
