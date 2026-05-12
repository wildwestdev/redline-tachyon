//==============================================================
//  File: TripCodableTests.swift
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
//    Defines TripCodableTests for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 11/05/2026 Add Codable coverage for per-session location fields.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
@testable import Speed_Demon
import XCTest

@MainActor final class TripCodableTests: XCTestCase {
  func testTripDecodingFallsBackForMissingLegacyFields() throws {
    let json = Data(
      """
      {
        \"name\": \"Legacy Trip\"
      }
      """.utf8)

    let trip = try JSONDecoder().decode(Trip.self, from: json)

    XCTAssertEqual(trip.name, "Legacy Trip")
    XCTAssertEqual(trip.distanceMeters, 0)
    XCTAssertFalse(trip.isRunning)
    XCTAssertTrue(trip.sessions.isEmpty)
  }

  func testTripEncodingRoundTripsCoreFields() throws {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let session = TripSession(
      startDate: start,
      endDate: start.addingTimeInterval(60),
      distanceMeters: 500)

    let original = Trip(
      id: UUID(),
      name: "Trip A",
      distanceMeters: 12345,
      isRunning: true,
      sessions: [session])

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Trip.self, from: data)

    XCTAssertEqual(decoded.id, original.id)
    XCTAssertEqual(decoded.name, original.name)
    XCTAssertEqual(decoded.distanceMeters, original.distanceMeters)
    XCTAssertEqual(decoded.isRunning, original.isRunning)
    XCTAssertEqual(decoded.sessions.count, 1)
  }

  func testTripSessionLocationFieldsRoundTripViaTripCodable() throws {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let session = TripSession(
      startDate: start,
      endDate: start.addingTimeInterval(90),
      distanceMeters: 700,
      startLocationDescription: "Main St, Sydney",
      endLocationDescription: "George St, Sydney")
    var original = Trip(
      id: UUID(),
      name: "Location Trip",
      distanceMeters: 700,
      isRunning: false,
      sessions: [session])
    original.startLocationDescription = "Main St, Sydney"
    original.endLocationDescription = "George St, Sydney"

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Trip.self, from: data)
    let roundTripSession = try XCTUnwrap(decoded.sessions.first)

    XCTAssertEqual(roundTripSession.startLocationDescription, "Main St, Sydney")
    XCTAssertEqual(roundTripSession.endLocationDescription, "George St, Sydney")
  }
}
