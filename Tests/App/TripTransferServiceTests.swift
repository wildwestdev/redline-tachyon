//==============================================================
//  File: TripTransferServiceTests.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 12/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.47
//  Last Modified: 12/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Validates trip JSON/CSV export, JSON import, and printable history output.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 12/05/2026 Add tests for trip import/export formats and print-history text generation.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
@testable import Speed_Demon
import XCTest

final class TripTransferServiceTests: XCTestCase {
  func testExportJSONThenImportRoundTripsTrips() throws {
    let session = TripSession(
      id: UUID(),
      startDate: Date(timeIntervalSince1970: 1_700_000_200),
      endDate: Date(timeIntervalSince1970: 1_700_000_500),
      distanceMeters: 1234,
      startLocationDescription: "Start",
      endLocationDescription: "End")
    let trip = Trip(
      id: UUID(),
      name: "Morning",
      distanceMeters: 1234,
      isRunning: false,
      sessions: [session])

    let data = try TripTransferService.exportJSONData(trips: [trip])
    let imported = try TripTransferService.importTrips(from: data)

    XCTAssertEqual(imported.count, 1)
    XCTAssertEqual(imported[0].name, "Morning")
    XCTAssertEqual(imported[0].distanceMeters, 1234, accuracy: 0.001)
    XCTAssertEqual(imported[0].sessions.count, 1)
    XCTAssertEqual(imported[0].sessions[0].startLocationDescription, "Start")
    XCTAssertEqual(imported[0].sessions[0].endLocationDescription, "End")
  }

  func testExportCSVIncludesHeaderAndTripName() {
    let trip = Trip(name: "Road Trip", distanceMeters: 4567, isRunning: false, sessions: [])
    let csv = TripTransferService.exportCSVString(trips: [trip])

    XCTAssertTrue(csv.contains("trip_id,trip_name,trip_distance_m"))
    XCTAssertTrue(csv.contains("\"Road Trip\""))
  }

  func testPrintableHistoryTextIncludesSessionAndDistance() {
    let trip = Trip(
      name: "History",
      distanceMeters: 1000,
      isRunning: false,
      sessions: [
        TripSession(
          startDate: Date(timeIntervalSince1970: 1_700_000_000),
          endDate: Date(timeIntervalSince1970: 1_700_000_060),
          distanceMeters: 1000,
          startLocationDescription: "A",
          endLocationDescription: "B")
      ])
    let text = TripTransferService.printableHistoryText(for: trip, useImperialUnits: false)

    XCTAssertTrue(text.contains("History"))
    XCTAssertTrue(text.contains("Session 1"))
    XCTAssertTrue(text.contains("Distance"))
  }
}
