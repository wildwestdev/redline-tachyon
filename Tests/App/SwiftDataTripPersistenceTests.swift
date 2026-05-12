//==============================================================
//  File: SwiftDataTripPersistenceTests.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.51
//  Last Modified: 13/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines SwiftDataTripPersistenceTests for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 11/05/2026 Add in-memory persistence tests for save/load and replacement behavior.
//  Craig Little 11/05/2026 Replace IUO test state with safe optional unwrapping for lint compliance.
//  Craig Little 12/05/2026 Reuse one shared in-memory SwiftData persistence instance to stabilize device test execution.
//  Craig Little 13/05/2026 Add coverage for UUID collision repair and preserving duplicate trip names.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
@testable import Speed_Demon
import XCTest

@MainActor final class SwiftDataTripPersistenceTests: XCTestCase {
  private static var sharedPersistence: SwiftDataTripPersistence?

  override func setUpWithError() throws {
    try super.setUpWithError()
    if Self.sharedPersistence == nil {
      Self.sharedPersistence = try SwiftDataTripPersistence.makeInMemoryForTests()
    }
    Self.sharedPersistence?.replaceTrips(with: [])
  }

  func testReplaceTripsThenLoadTripsRoundTripsTripAndSessionFields() {
    guard let persistence = Self.sharedPersistence else {
      XCTFail("Shared persistence should be initialized in setUpWithError().")
      return
    }

    let now = Date(timeIntervalSince1970: 1_700_000_100)
    let session1 = TripSession(
      id: UUID(),
      startDate: now,
      endDate: now.addingTimeInterval(60),
      distanceMeters: 1500,
      startLocationDescription: "Start A",
      endLocationDescription: "End A")
    let session2 = TripSession(
      id: UUID(),
      startDate: now.addingTimeInterval(120),
      endDate: nil,
      distanceMeters: 200,
      startLocationDescription: "Start B",
      endLocationDescription: nil)

    var trip = Trip(
      id: UUID(),
      name: "RoundTrip",
      distanceMeters: 1700,
      isRunning: true,
      sessions: [session1, session2])
    trip.startLocationDescription = "Trip Start"
    trip.endLocationDescription = "Trip End"

    persistence.replaceTrips(with: [trip])
    let loaded = persistence.loadTrips()

    XCTAssertEqual(loaded.count, 1)
    XCTAssertEqual(loaded[0].id, trip.id)
    XCTAssertEqual(loaded[0].name, "RoundTrip")
    XCTAssertEqual(loaded[0].distanceMeters, 1700, accuracy: 0.0001)
    XCTAssertTrue(loaded[0].isRunning)
    XCTAssertEqual(loaded[0].startLocationDescription, "Trip Start")
    XCTAssertEqual(loaded[0].endLocationDescription, "Trip End")
    XCTAssertEqual(loaded[0].sessions.count, 2)
    XCTAssertEqual(loaded[0].sessions[0].startLocationDescription, "Start A")
    XCTAssertEqual(loaded[0].sessions[0].endLocationDescription, "End A")
    XCTAssertEqual(loaded[0].sessions[1].startLocationDescription, "Start B")
    XCTAssertNil(loaded[0].sessions[1].endLocationDescription)
  }

  func testReplaceTripsOverwritesPreviousSnapshot() {
    guard let persistence = Self.sharedPersistence else {
      XCTFail("Shared persistence should be initialized in setUpWithError().")
      return
    }

    let first = Trip(name: "First", distanceMeters: 1000, isRunning: false, sessions: [])
    let second = Trip(name: "Second", distanceMeters: 2000, isRunning: false, sessions: [])

    persistence.replaceTrips(with: [first])
    persistence.replaceTrips(with: [second])

    let loaded = persistence.loadTrips()
    XCTAssertEqual(loaded.count, 1)
    XCTAssertEqual(loaded[0].name, "Second")
    XCTAssertEqual(loaded[0].distanceMeters, 2000, accuracy: 0.0001)
  }

  func testLoadTripsReturnsNameSortedOrder() {
    guard let persistence = Self.sharedPersistence else {
      XCTFail("Shared persistence should be initialized in setUpWithError().")
      return
    }

    let beta = Trip(name: "Beta", distanceMeters: 10, isRunning: false, sessions: [])
    let alpha = Trip(name: "Alpha", distanceMeters: 20, isRunning: false, sessions: [])

    persistence.replaceTrips(with: [beta, alpha])
    let loaded = persistence.loadTrips()

    XCTAssertEqual(loaded.map(\.name), ["Alpha", "Beta"])
  }

  func testReplaceTripsPreservesDuplicateNamesWithDistinctTripIDs() {
    guard let persistence = Self.sharedPersistence else {
      XCTFail("Shared persistence should be initialized in setUpWithError().")
      return
    }

    let duplicateName = "Work Commute"
    let first = Trip(name: duplicateName, distanceMeters: 1000, isRunning: false, sessions: [])
    let second = Trip(name: duplicateName, distanceMeters: 2000, isRunning: false, sessions: [])

    persistence.replaceTrips(with: [first, second])
    let loaded = persistence.loadTrips()

    XCTAssertEqual(loaded.count, 2)
    XCTAssertEqual(loaded[0].name, duplicateName)
    XCTAssertEqual(loaded[1].name, duplicateName)
    XCTAssertNotEqual(loaded[0].id, loaded[1].id)
  }

  func testReplaceTripsRepairsDuplicateTripIDs() {
    guard let persistence = Self.sharedPersistence else {
      XCTFail("Shared persistence should be initialized in setUpWithError().")
      return
    }

    let sharedTripID = UUID()
    let first = Trip(id: sharedTripID, name: "Trip One", distanceMeters: 10, isRunning: false, sessions: [])
    let second = Trip(id: sharedTripID, name: "Trip Two", distanceMeters: 20, isRunning: false, sessions: [])

    persistence.replaceTrips(with: [first, second])
    let loaded = persistence.loadTrips()
    let loadedIDs = loaded.map(\.id)
    let uniqueIDs = Set(loadedIDs)

    XCTAssertEqual(loaded.count, 2)
    XCTAssertEqual(uniqueIDs.count, 2)
  }

  func testReplaceTripsRepairsDuplicateSessionIDsWithinTrip() {
    guard let persistence = Self.sharedPersistence else {
      XCTFail("Shared persistence should be initialized in setUpWithError().")
      return
    }

    let sharedSessionID = UUID()
    let start = Date(timeIntervalSince1970: 1_700_001_000)
    let sessionOne = TripSession(
      id: sharedSessionID,
      startDate: start,
      endDate: start.addingTimeInterval(30),
      distanceMeters: 100)
    let sessionTwo = TripSession(
      id: sharedSessionID,
      startDate: start.addingTimeInterval(60),
      endDate: start.addingTimeInterval(120),
      distanceMeters: 200)
    let trip = Trip(
      id: UUID(),
      name: "Session Collision",
      distanceMeters: 300,
      isRunning: false,
      sessions: [sessionOne, sessionTwo])

    persistence.replaceTrips(with: [trip])
    let loaded = persistence.loadTrips()
    guard let loadedTrip = loaded.first else {
      XCTFail("Expected one loaded trip.")
      return
    }

    XCTAssertEqual(loadedTrip.sessions.count, 2)
    XCTAssertEqual(Set(loadedTrip.sessions.map(\.id)).count, 2)
  }
}
