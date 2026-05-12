//==============================================================
//  File: AutoPauseCoordinatorTests.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 12/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.26
//  Last Modified: 12/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Verifies auto-pause and auto-resume trip transitions.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 12/05/2026 Add unit coverage for auto-pause threshold, auto-pause session closure, and auto-resume session start.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
@testable import Speed_Demon
import XCTest

final class AutoPauseCoordinatorTests: XCTestCase {
  func testEvaluateStationaryTransitionDelaysPauseUntilThreshold() {
    let now = Date()

    let first = AutoPauseCoordinator.evaluateStationaryTransition(
      now: now,
      autoPauseMinutes: 2,
      isMoving: false,
      hasRunningTrips: true,
      stationarySince: nil)
    XCTAssertEqual(first.updatedStationarySince, now)
    XCTAssertFalse(first.shouldAutoPause)

    let beforeThreshold = AutoPauseCoordinator.evaluateStationaryTransition(
      now: now.addingTimeInterval(119),
      autoPauseMinutes: 2,
      isMoving: false,
      hasRunningTrips: true,
      stationarySince: first.updatedStationarySince)
    XCTAssertFalse(beforeThreshold.shouldAutoPause)

    let atThreshold = AutoPauseCoordinator.evaluateStationaryTransition(
      now: now.addingTimeInterval(120),
      autoPauseMinutes: 2,
      isMoving: false,
      hasRunningTrips: true,
      stationarySince: first.updatedStationarySince)
    XCTAssertTrue(atThreshold.shouldAutoPause)
  }

  func testAutoPauseRunningTripsStopsRunningTripAndClosesOpenSession() {
    let tripID = UUID()
    let now = Date()
    let openSession = TripSession(
      startDate: now.addingTimeInterval(-300),
      endDate: nil,
      distanceMeters: 1250)
    var trips = [
      Trip(
        id: tripID,
        name: "Commute",
        distanceMeters: 1250,
        isRunning: true,
        sessions: [openSession])
    ]
    var autoPausedTripIDs = Set<UUID>()

    let paused = AutoPauseCoordinator.autoPauseRunningTrips(
      trips: &trips,
      autoPausedTripIDs: &autoPausedTripIDs,
      now: now,
      place: "George St, Sydney")

    XCTAssertTrue(paused)
    XCTAssertFalse(trips[0].isRunning)
    XCTAssertEqual(autoPausedTripIDs, [tripID])
    XCTAssertEqual(trips[0].sessions.count, 1)
    XCTAssertEqual(trips[0].sessions[0].endDate, now)
    XCTAssertEqual(trips[0].sessions[0].endLocationDescription, "George St, Sydney")
    XCTAssertEqual(trips[0].endLocationDescription, "George St, Sydney")
  }

  func testResumeAutoPausedTripsRestartsTripAndCreatesNewSession() {
    let tripID = UUID()
    let now = Date()
    let completedSession = TripSession(
      startDate: now.addingTimeInterval(-600),
      endDate: now.addingTimeInterval(-300),
      distanceMeters: 900)
    var trips = [
      Trip(
        id: tripID,
        name: "Errands",
        distanceMeters: 900,
        isRunning: false,
        sessions: [completedSession])
    ]
    var autoPausedTripIDs: Set<UUID> = [tripID]

    let resumedTrip = AutoPauseCoordinator.resumeAutoPausedTrips(
      trips: &trips,
      autoPausedTripIDs: &autoPausedTripIDs,
      now: now,
      place: "Parramatta Rd, Sydney")

    XCTAssertNotNil(resumedTrip)
    XCTAssertTrue(trips[0].isRunning)
    XCTAssertTrue(autoPausedTripIDs.isEmpty)
    XCTAssertEqual(trips[0].sessions.count, 2)
    XCTAssertEqual(trips[0].sessions[1].startDate, now)
    XCTAssertNil(trips[0].sessions[1].endDate)
    XCTAssertEqual(trips[0].sessions[1].startLocationDescription, "Parramatta Rd, Sydney")
    XCTAssertEqual(trips[0].startLocationDescription, "Parramatta Rd, Sydney")
  }
}
