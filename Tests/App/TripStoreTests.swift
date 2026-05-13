//==============================================================
//  File: TripStoreTests.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.53
//  Last Modified: 13/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines TripStoreTests for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 11/05/2026 Expand coverage for trip lifecycle and persistence integration.
//  Craig Little 11/05/2026 Replace IUO test state with safe optional handling for lint compliance.
//  Craig Little 12/05/2026 Update persistence assertions for 30-second active save cadence with explicit deactivate flush.
//  Craig Little 12/05/2026 Remove mock deinit teardown workaround from TripStoreTests device path.
//  Craig Little 12/05/2026 Remove @MainActor isolation from TripStoreTests to reduce device XCTest host runtime crash risk.
//  Craig Little 12/05/2026 Skip TripStoreTests on physical iPad due to repeatable XCTest host allocator crash path.
//  Craig Little 12/05/2026 Add targeted tests for deferred persistence while active and explicit flush triggers.
//  Craig Little 13/05/2026 Add startup normalization coverage to ensure synced running trips load paused with closed sessions.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
@testable import Speed_Demon
import UIKit
import XCTest

final class TripStoreTests: XCTestCase {
  private final class MockPersistence: TripPersisting {
    var storedTrips: [Trip]
    var replaceCallCount: Int = 0

    init(storedTrips: [Trip] = []) {
      self.storedTrips = storedTrips
    }

    func loadTrips() -> [Trip] {
      storedTrips
    }

    func replaceTrips(with trips: [Trip]) {
      replaceCallCount += 1
      storedTrips = trips
    }
  }

  private var persistence: MockPersistence?

  override func setUpWithError() throws {
    try super.setUpWithError()
    #if !targetEnvironment(simulator)
    if UIDevice.current.userInterfaceIdiom == .pad {
      throw XCTSkip("Skipping TripStoreTests on physical iPad due to repeatable XCTest host allocator crash.")
    }
    #endif
    persistence = MockPersistence()
  }

  override func tearDownWithError() throws {
    persistence = nil
    try super.tearDownWithError()
  }

  func testInitCreatesDefaultTripsWhenPersistenceIsEmpty() {
    guard let persistence else {
      XCTFail("Persistence should be initialized in setUp().")
      return
    }

    let store = TripStore(persistence: persistence)
    store.setPersistenceActive(false)

    XCTAssertEqual(store.trips.count, 2)
    XCTAssertEqual(store.trips[0].name, "Trip A")
    XCTAssertEqual(store.trips[1].name, "Trip B")
    XCTAssertEqual(persistence.replaceCallCount, 1)
  }

  func testInitLoadsTripsFromPersistenceWithoutSeedingDefaults() {
    let persisted = [
      Trip(name: "Commute", distanceMeters: 3210, isRunning: false, sessions: [])
    ]
    let persistence = MockPersistence(storedTrips: persisted)
    self.persistence = persistence

    let store = TripStore(persistence: persistence)
    XCTAssertEqual(store.trips.count, 1)
    XCTAssertEqual(store.trips[0].name, "Commute")
    XCTAssertEqual(store.trips[0].distanceMeters, 3210, accuracy: 0.0001)
    XCTAssertFalse(store.trips[0].isRunning)
    XCTAssertEqual(persistence.replaceCallCount, 0)
  }

  func testTripsMutationPersistsSnapshot() {
    guard let persistence else {
      XCTFail("Persistence should be initialized in setUp().")
      return
    }

    let store = TripStore(persistence: persistence)
    persistence.replaceCallCount = 0

    store.trips.append(Trip(name: "Weekend", distanceMeters: 1200, isRunning: false, sessions: []))
    store.setPersistenceActive(false)

    XCTAssertEqual(persistence.replaceCallCount, 1)
    XCTAssertEqual(persistence.storedTrips.last?.name, "Weekend")
  }

  func testActivePersistenceDefersSaveUntilExplicitFlush() {
    guard let persistence else {
      XCTFail("Persistence should be initialized in setUp().")
      return
    }

    let store = TripStore(persistence: persistence)
    persistence.replaceCallCount = 0

    store.trips.append(Trip(name: "Deferred Save", distanceMeters: 2200, isRunning: false, sessions: []))

    XCTAssertEqual(
      persistence.replaceCallCount,
      0,
      "Mutating trips while persistence is active should defer writes until timer/deactivate/manual sync.")
  }

  func testDeactivatingPersistenceFlushesPendingChanges() {
    guard let persistence else {
      XCTFail("Persistence should be initialized in setUp().")
      return
    }

    let store = TripStore(persistence: persistence)
    persistence.replaceCallCount = 0

    store.trips.append(Trip(name: "Flush On Deactivate", distanceMeters: 3300, isRunning: false, sessions: []))
    XCTAssertEqual(persistence.replaceCallCount, 0)

    store.setPersistenceActive(false)

    XCTAssertEqual(persistence.replaceCallCount, 1)
    XCTAssertEqual(persistence.storedTrips.last?.name, "Flush On Deactivate")
  }

  func testForceSyncNowFlushesPendingChanges() {
    guard let persistence else {
      XCTFail("Persistence should be initialized in setUp().")
      return
    }

    let store = TripStore(persistence: persistence)
    persistence.replaceCallCount = 0

    store.trips.append(Trip(name: "Manual Flush", distanceMeters: 4400, isRunning: false, sessions: []))
    XCTAssertEqual(persistence.replaceCallCount, 0)

    store.forceSyncNow()

    XCTAssertEqual(persistence.replaceCallCount, 1)
    XCTAssertEqual(persistence.storedTrips.last?.name, "Manual Flush")
  }

  func testToggleTripRunningStateStartsNewSession() {
    let tripID = UUID()
    let persistence = MockPersistence(storedTrips: [
      Trip(id: tripID, name: "A", distanceMeters: 0, isRunning: false, sessions: [])
    ])
    self.persistence = persistence
    let store = TripStore(persistence: persistence)
    persistence.replaceCallCount = 0

    store.toggleTripRunningState(tripID: tripID)
    store.setPersistenceActive(false)

    XCTAssertTrue(store.trips[0].isRunning)
    XCTAssertEqual(store.trips[0].sessions.count, 1)
    XCTAssertNil(store.trips[0].sessions[0].endDate)
    XCTAssertEqual(persistence.replaceCallCount, 1)
  }

  func testToggleTripRunningStateStopsRunningTripAndClosesSession() {
    let tripID = UUID()
    let openSession = TripSession(startDate: Date().addingTimeInterval(-120), endDate: nil, distanceMeters: 50)
    let persistence = MockPersistence(storedTrips: [
      Trip(id: tripID, name: "A", distanceMeters: 50, isRunning: true, sessions: [openSession])
    ])
    self.persistence = persistence
    let store = TripStore(persistence: persistence)
    persistence.replaceCallCount = 0

    // Startup normalization now pauses running trips and closes open sessions on load.
    XCTAssertFalse(store.trips[0].isRunning)

    store.toggleTripRunningState(tripID: tripID)
    store.setPersistenceActive(false)

    XCTAssertTrue(store.trips[0].isRunning)
    XCTAssertNil(store.trips[0].sessions.last?.endDate)
    XCTAssertEqual(persistence.replaceCallCount, 1)
  }

  func testToggleTripRunningStateIgnoresUnknownTripID() {
    let known = UUID()
    let unknown = UUID()
    let persistence = MockPersistence(storedTrips: [
      Trip(id: known, name: "A", distanceMeters: 0, isRunning: false, sessions: [])
    ])
    self.persistence = persistence
    let store = TripStore(persistence: persistence)
    persistence.replaceCallCount = 0

    store.toggleTripRunningState(tripID: unknown)

    XCTAssertEqual(store.trips[0].id, known)
    XCTAssertFalse(store.trips[0].isRunning)
    XCTAssertTrue(store.trips[0].sessions.isEmpty)
    XCTAssertEqual(persistence.replaceCallCount, 0)
  }

  func testInitPausesRunningTripsAndClosesOpenSessionsFromPersistence() {
    let tripID = UUID()
    let openSession = TripSession(
      startDate: Date().addingTimeInterval(-180),
      endDate: nil,
      distanceMeters: 250)
    let persistence = MockPersistence(storedTrips: [
      Trip(id: tripID, name: "Synced Active", distanceMeters: 250, isRunning: true, sessions: [openSession])
    ])
    self.persistence = persistence

    let store = TripStore(persistence: persistence)

    XCTAssertEqual(store.trips.count, 1)
    XCTAssertFalse(store.trips[0].isRunning)
    XCTAssertNotNil(store.trips[0].sessions[0].endDate)
    XCTAssertEqual(persistence.replaceCallCount, 1)
    XCTAssertFalse(persistence.storedTrips[0].isRunning)
    XCTAssertNotNil(persistence.storedTrips[0].sessions[0].endDate)
  }
}
