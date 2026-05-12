//==============================================================
//  File: SwiftDataTripPersistence.swift
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
//    Provides SwiftData + CloudKit persistence for Trip and TripSession
//    data with conversion helpers used by TripStore.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 11/05/2026 Fix CloudKit SwiftData schema constraints and add safe container fallback.
//  Craig Little 11/05/2026 Add protocol conformance for injectable trip persistence.
//  Craig Little 11/05/2026 Add in-memory initializer support for persistence unit tests.
//  Craig Little 12/05/2026 Expose active persistence sync mode for read-only diagnostics UI.
//  Craig Little 12/05/2026 Mark CloudKit-backed persistence mode so TripStore can avoid default-trip seeding before sync.
//  Craig Little 13/05/2026 Replace delete/insert persistence with ID-based upsert to prevent CloudKit sync duplicates.
//  Craig Little 13/05/2026 Remove schema-level unique constraints to avoid CloudKit/SwiftData fallback on existing stores.
//  Craig Little 13/05/2026 Reconcile duplicated imported CloudKit rows by collapsing identical trip/session records on load.
//  Craig Little 13/05/2026 Enforce unique UUIDs for trip/session records while allowing duplicate trip names.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import SwiftData

/// Defines operations needed by `TripStore` to persist trip snapshots.
protocol TripPersisting {
  /// Indicates whether this persistence is backed by cloud sync.
  var isCloudBacked: Bool { get }
  /// Loads all persisted trips.
  func loadTrips() -> [Trip]
  /// Replaces persisted trips with a complete snapshot.
  func replaceTrips(with trips: [Trip])
}

@Model final class TripSessionRecord {
  var id = UUID()
  var startDate = Date()
  var endDate: Date?
  var distanceMeters: Double = 0
  var startLocationDescription: String?
  var endLocationDescription: String?
  var trip: TripRecord?

  init(
    id: UUID,
    startDate: Date,
    endDate: Date?,
    distanceMeters: Double,
    startLocationDescription: String?,
    endLocationDescription: String?)
  {
    self.id = id
    self.startDate = startDate
    self.endDate = endDate
    self.distanceMeters = distanceMeters
    self.startLocationDescription = startLocationDescription
    self.endLocationDescription = endLocationDescription
  }
}

@Model final class TripRecord {
  var id = UUID()
  var name: String = ""
  var distanceMeters: Double = 0
  var isRunning: Bool = false
  var startLocationDescription: String?
  var endLocationDescription: String?
  @Relationship(deleteRule: .cascade, inverse: \TripSessionRecord.trip) var sessions: [TripSessionRecord]? = []

  init(
    id: UUID,
    name: String,
    distanceMeters: Double,
    isRunning: Bool,
    startLocationDescription: String?,
    endLocationDescription: String?,
    sessions: [TripSessionRecord])
  {
    self.id = id
    self.name = name
    self.distanceMeters = distanceMeters
    self.isRunning = isRunning
    self.startLocationDescription = startLocationDescription
    self.endLocationDescription = endLocationDescription
    self.sessions = sessions
  }
}

/// Owns the SwiftData model container used for local and iCloud sync persistence.
final class SwiftDataTripPersistence: TripPersisting {
  static let shared = SwiftDataTripPersistence()

  private let modelContainer: ModelContainer
  private let modelContext: ModelContext
  private(set) var isUsingCloudKitSync: Bool = false
  var isCloudBacked: Bool {
    isUsingCloudKitSync
  }

  init() {
    let schema = Schema([TripRecord.self, TripSessionRecord.self])
    let config = ModelConfiguration(
      "SpeedDemonTrips",
      schema: schema,
      isStoredInMemoryOnly: false,
      allowsSave: true,
      groupContainer: .automatic,
      cloudKitDatabase: .private("iCloud.au.com.nickelrose.speed-demon"))

    do {
      modelContainer = try ModelContainer(for: schema, configurations: [config])
      modelContext = ModelContext(modelContainer)
      isUsingCloudKitSync = true
    } catch {
      print("Failed to initialize CloudKit SwiftData container, falling back to local store: \(error)")
      let localConfig = ModelConfiguration(
        "SpeedDemonTripsLocalFallback",
        schema: schema,
        isStoredInMemoryOnly: false,
        allowsSave: true,
        groupContainer: .automatic,
        cloudKitDatabase: .none)
      do {
        modelContainer = try ModelContainer(for: schema, configurations: [localConfig])
        modelContext = ModelContext(modelContainer)
        isUsingCloudKitSync = false
      } catch {
        fatalError("Failed to initialize fallback SwiftData container: \(error)")
      }
    }
  }

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    modelContext = ModelContext(modelContainer)
    isUsingCloudKitSync = false
  }

  static func makeInMemoryForTests() throws -> SwiftDataTripPersistence {
    let schema = Schema([TripRecord.self, TripSessionRecord.self])
    let config = ModelConfiguration(
      "SpeedDemonTripsTests",
      schema: schema,
      isStoredInMemoryOnly: true,
      allowsSave: true,
      groupContainer: .none,
      cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [config])
    return SwiftDataTripPersistence(modelContainer: container)
  }

  /// Fetches all stored trips sorted by name for stable UI ordering.
  func loadTrips() -> [Trip] {
    let descriptor = FetchDescriptor<TripRecord>(sortBy: [SortDescriptor(\.name)])
    do {
      let records = try modelContext.fetch(descriptor)
      let normalizedRecords = normalizeUniqueIdentifiersIfNeeded(records)
      if normalizedRecords.didMutate {
        try modelContext.save()
      }
      return normalizedRecords.records.map(toTrip)
    } catch {
      print("Failed to fetch trips from SwiftData: \(error)")
      return []
    }
  }

  /// Replaces stored trips with a new full snapshot.
  func replaceTrips(with trips: [Trip]) {
    do {
      let normalizedTrips = ensureUniqueTripAndSessionIDs(in: trips)
      let existing = try modelContext.fetch(FetchDescriptor<TripRecord>())
      var existingByID: [UUID: TripRecord] = [:]
      for record in existing {
        existingByID[record.id] = record
      }

      var incomingTripIDs = Set<UUID>()
      for trip in normalizedTrips {
        incomingTripIDs.insert(trip.id)
        if let existingRecord = existingByID[trip.id] {
          update(existingRecord, from: trip)
        } else {
          modelContext.insert(toRecord(trip))
        }
      }

      for record in existing where !incomingTripIDs.contains(record.id) {
        modelContext.delete(record)
      }

      try modelContext.save()
    } catch {
      print("Failed to persist trips to SwiftData: \(error)")
    }
  }
}

extension TripPersisting {
  var isCloudBacked: Bool {
    false
  }
}

private extension SwiftDataTripPersistence {
  func toTrip(_ record: TripRecord) -> Trip {
    let sessions = (record.sessions ?? [])
      .map { sessionRecord in
        TripSession(
          id: sessionRecord.id,
          startDate: sessionRecord.startDate,
          endDate: sessionRecord.endDate,
          distanceMeters: sessionRecord.distanceMeters,
          startLocationDescription: sessionRecord.startLocationDescription,
          endLocationDescription: sessionRecord.endLocationDescription)
      }
      .sorted(by: { $0.startDate < $1.startDate })

    var trip = Trip(
      id: record.id,
      name: record.name,
      distanceMeters: record.distanceMeters,
      isRunning: record.isRunning,
      sessions: sessions)
    trip.startLocationDescription = record.startLocationDescription
    trip.endLocationDescription = record.endLocationDescription
    return trip
  }

  func toRecord(_ trip: Trip) -> TripRecord {
    let sessions = trip.sessions.map { session in
      TripSessionRecord(
        id: session.id,
        startDate: session.startDate,
        endDate: session.endDate,
        distanceMeters: session.distanceMeters,
        startLocationDescription: session.startLocationDescription,
        endLocationDescription: session.endLocationDescription)
    }

    return TripRecord(
      id: trip.id,
      name: trip.name,
      distanceMeters: trip.distanceMeters,
      isRunning: trip.isRunning,
      startLocationDescription: trip.startLocationDescription,
      endLocationDescription: trip.endLocationDescription,
      sessions: sessions)
  }

  func update(_ record: TripRecord, from trip: Trip) {
    record.name = trip.name
    record.distanceMeters = trip.distanceMeters
    record.isRunning = trip.isRunning
    record.startLocationDescription = trip.startLocationDescription
    record.endLocationDescription = trip.endLocationDescription

    var existingSessionsByID: [UUID: TripSessionRecord] = [:]
    for session in record.sessions ?? [] {
      existingSessionsByID[session.id] = session
    }

    var incomingSessionIDs = Set<UUID>()
    for session in trip.sessions {
      incomingSessionIDs.insert(session.id)
      if let existingSession = existingSessionsByID[session.id] {
        existingSession.startDate = session.startDate
        existingSession.endDate = session.endDate
        existingSession.distanceMeters = session.distanceMeters
        existingSession.startLocationDescription = session.startLocationDescription
        existingSession.endLocationDescription = session.endLocationDescription
      } else {
        let sessionRecord = TripSessionRecord(
          id: session.id,
          startDate: session.startDate,
          endDate: session.endDate,
          distanceMeters: session.distanceMeters,
          startLocationDescription: session.startLocationDescription,
          endLocationDescription: session.endLocationDescription)
        sessionRecord.trip = record
        record.sessions?.append(sessionRecord)
      }
    }

    record.sessions = (record.sessions ?? []).filter { incomingSessionIDs.contains($0.id) }
  }

  func normalizeUniqueIdentifiersIfNeeded(_ records: [TripRecord]) -> (records: [TripRecord], didMutate: Bool) {
    var seenTripIDs = Set<UUID>()
    var didMutate = false

    for record in records {
      if seenTripIDs.contains(record.id) {
        record.id = UUID()
        didMutate = true
      }
      seenTripIDs.insert(record.id)

      if normalizeSessionIdentifiers(in: record) {
        didMutate = true
      }
    }

    let sorted = records.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    return (sorted, didMutate)
  }

  func normalizeSessionIdentifiers(in record: TripRecord) -> Bool {
    guard let sessions = record.sessions, sessions.count > 1 else {
      return false
    }

    var seenSessionIDs = Set<UUID>()
    var didMutate = false

    for session in sessions {
      if seenSessionIDs.contains(session.id) {
        session.id = UUID()
        didMutate = true
      }
      seenSessionIDs.insert(session.id)
    }

    return didMutate
  }

  func ensureUniqueTripAndSessionIDs(in trips: [Trip]) -> [Trip] {
    var seenTripIDs = Set<UUID>()
    var normalizedTrips: [Trip] = []

    for trip in trips {
      var resolvedTripID = trip.id
      if seenTripIDs.contains(resolvedTripID) {
        resolvedTripID = UUID()
      }
      seenTripIDs.insert(resolvedTripID)

      var seenSessionIDs = Set<UUID>()
      let normalizedSessions = trip.sessions.map { session in
        var resolvedSessionID = session.id
        if seenSessionIDs.contains(resolvedSessionID) {
          resolvedSessionID = UUID()
        }
        seenSessionIDs.insert(resolvedSessionID)

        return TripSession(
          id: resolvedSessionID,
          startDate: session.startDate,
          endDate: session.endDate,
          distanceMeters: session.distanceMeters,
          startLocationDescription: session.startLocationDescription,
          endLocationDescription: session.endLocationDescription)
      }

      var normalizedTrip = Trip(
        id: resolvedTripID,
        name: trip.name,
        distanceMeters: trip.distanceMeters,
        isRunning: trip.isRunning,
        sessions: normalizedSessions)
      normalizedTrip.startLocationDescription = trip.startLocationDescription
      normalizedTrip.endLocationDescription = trip.endLocationDescription
      normalizedTrips.append(normalizedTrip)
    }

    return normalizedTrips
  }
}
