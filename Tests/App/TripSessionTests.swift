//==============================================================
//  File: TripSessionTests.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.11
//  Last Modified: 11/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines TripSessionTests for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 11/05/2026 Add TripSession location field initialization coverage.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
@testable import Speed_Demon
import XCTest

final class TripSessionTests: XCTestCase {
  func testDurationUsesEndDateWhenPresent() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let end = start.addingTimeInterval(125)

    let session = TripSession(
      id: UUID(),
      startDate: start,
      endDate: end,
      distanceMeters: 1000)

    XCTAssertEqual(session.duration, 125, accuracy: 0.0001)
  }

  func testDistanceKmAndAverageSpeedKmh() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let end = start.addingTimeInterval(1800)

    let session = TripSession(
      id: UUID(),
      startDate: start,
      endDate: end,
      distanceMeters: 5000)

    XCTAssertEqual(session.distanceKm, 5.0, accuracy: 0.0001)
    XCTAssertEqual(session.averageSpeedKmh, 10.0, accuracy: 0.0001)
  }

  func testAverageSpeedIsZeroWhenDurationIsZero() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)

    let session = TripSession(
      id: UUID(),
      startDate: start,
      endDate: start,
      distanceMeters: 5000)

    XCTAssertEqual(session.averageSpeedKmh, 0)
  }

  func testInitStoresOptionalLocationDescriptions() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)

    let session = TripSession(
      startDate: start,
      endDate: nil,
      distanceMeters: 250,
      startLocationDescription: "Start",
      endLocationDescription: "End")

    XCTAssertEqual(session.startLocationDescription, "Start")
    XCTAssertEqual(session.endLocationDescription, "End")
  }
}
