//==============================================================
//  File: TripStore.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.47
//  Last Modified: 12/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines TripStore for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 11/05/2026 Add injectable persistence for deterministic unit testing.
//  Craig Little 11/05/2026 Make trip toggle updates atomic to avoid duplicate persistence writes.
//  Craig Little 12/05/2026 Skip default-trip seeding for cloud-backed persistence and add foreground refresh reload hook.
//  Craig Little 12/05/2026 Persist trip changes every 30 seconds while active with a dirty-flag timer and deactivate flush.
//  Craig Little 12/05/2026 Disable periodic save timer under XCTest to avoid device test-host instability.
//  Craig Little 12/05/2026 Add sync status state (Synced/Syncing/Local fallback) for main-screen diagnostics.
//  Craig Little 12/05/2026 Wire CloudKit event observation with main-thread delivery and active refresh polling for HAR-style sync.
//  Craig Little 12/05/2026 Add forceSyncNow action to flush pending changes and immediately refresh persisted cloud-backed trips.
//  Craig Little 12/05/2026 Add import/replace helpers for manual trip JSON import and explicit persistence flush behavior tests.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Combine
import CoreData
import Foundation

enum TripSyncStatus {
  case cloudConnected
  case uploading
  case importing
  case localFallback

  var displayText: String {
    switch self {
    case .cloudConnected:
      "Connected"
    case .uploading:
      "Uploading"
    case .importing:
      "Updating"
    case .localFallback:
      "Local only"
    }
  }
}

class TripStore: ObservableObject {
  static let shared = TripStore()
  @Published var trips: [Trip] = [] {
    didSet {
      markTripsDirtyForPersistence()
    }
  }

  @Published private(set) var syncStatus: TripSyncStatus = .localFallback

  private let persistence: TripPersisting
  private var isBootstrapping = false
  private var hasPendingPersistenceChanges = false
  private var isPersistenceActive = true
  private var periodicSaveTimer: Timer?
  private var cloudRefreshTimer: Timer?
  private var cloudEventCancellable: AnyCancellable?
  private let isRunningUnitTests: Bool

  init(persistence: TripPersisting = SwiftDataTripPersistence.shared) {
    self.persistence = persistence
    isRunningUnitTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    syncStatus = persistence.isCloudBacked ? .cloudConnected : .localFallback

    if !isRunningUnitTests {
      startPeriodicSaveTimer()
      startCloudRefreshTimer()
      startCloudEventObservation()
    }

    isBootstrapping = true
    loadTrips()
    isBootstrapping = false

    if trips.isEmpty, !persistence.isCloudBacked {
      // Default trips on first launch
      trips = [
        Trip(name: "Trip A"),
        Trip(name: "Trip B")
      ]
    }
  }

  // MARK: - Persistence

  private func markTripsDirtyForPersistence() {
    if isBootstrapping {
      return
    }

    hasPendingPersistenceChanges = true
    if persistence.isCloudBacked {
      syncStatus = .uploading
    } else {
      syncStatus = .localFallback
    }
  }

  private func saveTripsIfNeeded() {
    guard hasPendingPersistenceChanges else {
      return
    }

    persistence.replaceTrips(with: trips)
    hasPendingPersistenceChanges = false
    syncStatus = persistence.isCloudBacked ? .cloudConnected : .localFallback
  }

  private func loadTrips() {
    trips = persistence.loadTrips()
  }

  private func startPeriodicSaveTimer() {
    periodicSaveTimer?.invalidate()
    periodicSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
      guard let self, self.isPersistenceActive else {
        return
      }

      self.saveTripsIfNeeded()
    }
  }

  private func startCloudRefreshTimer() {
    guard persistence.isCloudBacked else {
      return
    }

    cloudRefreshTimer?.invalidate()
    cloudRefreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
      guard
        let self,
        self.isPersistenceActive,
        !self.hasPendingPersistenceChanges
      else {
        return
      }

      self.refreshFromPersistence()
    }
  }

  private func startCloudEventObservation() {
    guard persistence.isCloudBacked else {
      return
    }

    cloudEventCancellable = NotificationCenter.default.publisher(
      for: NSPersistentCloudKitContainer.eventChangedNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] notification in
        self?.handleCloudEvent(notification)
      }
  }

  private func handleCloudEvent(_ notification: Notification) {
    guard
      let event = notification.userInfo?[
        NSPersistentCloudKitContainer.eventNotificationUserInfoKey
      ]
      as? NSPersistentCloudKitContainer.Event
    else {
      return
    }

    switch event.type {
    case .import:
      if event.endDate == nil {
        syncStatus = .importing
      } else {
        refreshFromPersistence()
        syncStatus = hasPendingPersistenceChanges ? .uploading : .cloudConnected
      }
    case .export:
      if event.endDate == nil {
        syncStatus = .uploading
      } else {
        syncStatus = hasPendingPersistenceChanges ? .uploading : .cloudConnected
      }
    @unknown default:
      syncStatus = hasPendingPersistenceChanges ? .uploading : .cloudConnected
    }
  }

  /// Reloads persisted trips, intended for foreground refresh after cloud sync changes.
  func refreshFromPersistence() {
    let loadedTrips = persistence.loadTrips()
    guard !loadedTrips.isEmpty else {
      return
    }

    isBootstrapping = true
    trips = loadedTrips
    isBootstrapping = false
    hasPendingPersistenceChanges = false
    syncStatus = persistence.isCloudBacked ? .cloudConnected : .localFallback
  }

  /// Controls whether periodic persistence runs. When transitioning away from active,
  /// pending changes are flushed once for data safety.
  func setPersistenceActive(_ isActive: Bool) {
    if isPersistenceActive == isActive {
      return
    }

    isPersistenceActive = isActive
    if !isActive {
      saveTripsIfNeeded()
    }
  }

  /// Forces a sync cycle by flushing pending local changes and immediately reloading
  /// persisted data (including any recently imported cloud changes).
  func forceSyncNow() {
    saveTripsIfNeeded()
    refreshFromPersistence()
  }

  /// Replaces all in-memory trips and marks data for persistence.
  func replaceAllTrips(_ newTrips: [Trip]) {
    trips = newTrips
  }

  // MARK: - CarPlay Actions

  /// Toggles running state for the trip with the matching identifier.
  func toggleTripRunningState(tripID: UUID) {
    guard let index = trips.firstIndex(where: { $0.id == tripID }) else {
      return
    }

    var updatedTrip = trips[index]

    if updatedTrip.isRunning {
      updatedTrip.isRunning = false
      if let openSession = updatedTrip.sessions.lastIndex(where: { $0.endDate == nil }) {
        updatedTrip.sessions[openSession].endDate = Date()
      }
    } else {
      updatedTrip.isRunning = true
      updatedTrip.sessions.append(TripSession(startDate: Date()))
    }

    trips[index] = updatedTrip
  }
}
