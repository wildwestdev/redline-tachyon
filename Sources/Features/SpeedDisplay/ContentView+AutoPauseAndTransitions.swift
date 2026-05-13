//==============================================================
//  File: ContentView+AutoPauseAndTransitions.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 12/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.75
//  Last Modified: 13/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Splits auto-pause/resume logic and glass transition helpers from ContentView.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 12/05/2026 Move auto-pause/idle-lock helpers and add formatter helpers for motion/sync status test coverage.
//  Craig Little 13/05/2026 Prevent motion-sensor false positives from blocking auto-pause when speed remains near zero.
//  Craig Little 13/05/2026 Make auto-pause speed-driven for deterministic behavior during sustained stationary periods.
//  Craig Little 13/05/2026 Use configurable moving-speed threshold, align header version with project build, and reorder/flatten helper
//  types for SwiftLint file type order compliance, split-file build access fixes, and restore AutoPauseCoordinator for tests.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import SwiftUI
import UIKit

// MARK: - Glass Glimmer Transition

private struct GlassGlimmerAppearModifier: ViewModifier {
  let opacity: Double
  let scale: CGFloat
  let blur: CGFloat
  let highlightOpacity: Double

  func body(content: Content) -> some View {
    content
      .scaleEffect(scale)
      .opacity(opacity)
      .blur(radius: blur)
      .overlay(
        RoundedRectangle(cornerRadius: GlassTheme.Radius.medium, style: .continuous)
          .stroke(
            GlassTheme.highlight.opacity(highlightOpacity),
            lineWidth: 1.5)
          .blendMode(.screen))
      .shadow(
        color: GlassTheme.highlight.opacity(highlightOpacity * 0.8),
        radius: 16,
        x: 0,
        y: 0)
  }
}

enum StatusLineFormatter {
  static func motionStatusText(displayMotion: Bool, isLikelyMoving: Bool) -> String? {
    guard displayMotion else {
      return nil
    }

    return isLikelyMoving ? "Motion: moving" : "Motion: still"
  }

  static func syncStatusText(syncStatus: TripSyncStatus) -> String {
    "Sync: \(syncStatus.displayText)"
  }
}

enum AutoPauseCoordinator {
  static func evaluateStationaryTransition(
    now: Date,
    autoPauseMinutes: Int,
    isMoving: Bool,
    hasRunningTrips: Bool,
    stationarySince: Date?) -> (updatedStationarySince: Date?, shouldAutoPause: Bool)
  {
    if autoPauseMinutes == 0 {
      return (nil, false)
    }

    if isMoving {
      return (nil, false)
    }

    guard hasRunningTrips else {
      return (nil, false)
    }

    guard let stationarySince else {
      return (now, false)
    }

    let stationaryThreshold = TimeInterval(autoPauseMinutes * 60)
    let shouldPause = now.timeIntervalSince(stationarySince) >= stationaryThreshold
    return (stationarySince, shouldPause)
  }

  static func autoPauseRunningTrips(
    trips: inout [Trip],
    autoPausedTripIDs: inout Set<UUID>,
    now: Date,
    place: String) -> Bool
  {
    var pausedAnyTrip = false

    for index in trips.indices {
      guard trips[index].isRunning else {
        continue
      }

      trips[index].isRunning = false
      autoPausedTripIDs.insert(trips[index].id)
      pausedAnyTrip = true

      if let openIndex = trips[index].sessions.lastIndex(where: { $0.endDate == nil }) {
        trips[index].sessions[openIndex].endDate = now

        if !place.isEmpty {
          trips[index].sessions[openIndex].endLocationDescription = place
          trips[index].endLocationDescription = place
        }
      }
    }

    return pausedAnyTrip
  }

  static func resumeAutoPausedTrips(
    trips: inout [Trip],
    autoPausedTripIDs: inout Set<UUID>,
    now: Date,
    place: String) -> Trip?
  {
    guard !autoPausedTripIDs.isEmpty else {
      return nil
    }

    var resumedTrip: Trip?

    for index in trips.indices {
      let tripID = trips[index].id
      guard autoPausedTripIDs.contains(tripID), !trips[index].isRunning else {
        continue
      }

      trips[index].isRunning = true
      trips[index].sessions.append(
        TripSession(
          startDate: now,
          startLocationDescription: place.isEmpty ? nil : place))

      if !place.isEmpty {
        trips[index].startLocationDescription = place
      }

      autoPausedTripIDs.remove(tripID)
      resumedTrip = trips[index]
    }

    return resumedTrip
  }
}

extension ContentView {
  func updateIdleLockState() {
    let hasRunningTrip = tripStore.trips.contains(where: \.isRunning)
    UIApplication.shared.isIdleTimerDisabled = hasRunningTrip
  }

  func evaluateAutoPauseResume(at now: Date) {
    let isMoving = locationManager.speedKmh >= autoPauseMovingSpeedThresholdKmh

    let transition = AutoPauseCoordinator.evaluateStationaryTransition(
      now: now,
      autoPauseMinutes: autoPauseMinutes,
      isMoving: isMoving,
      hasRunningTrips: tripStore.trips.contains(where: \.isRunning),
      stationarySince: stationarySince)
    stationarySince = transition.updatedStationarySince

    if isMoving || autoPauseMinutes == 0 {
      resumeAutoPausedTrips(at: now)
      return
    }

    if transition.shouldAutoPause {
      autoPauseRunningTrips(at: now)
    }
  }

  func autoPauseRunningTrips(at now: Date) {
    let place = locationManager.currentPlaceSummary
    let pausedAnyTrip = AutoPauseCoordinator.autoPauseRunningTrips(
      trips: &tripStore.trips,
      autoPausedTripIDs: &autoPausedTripIDs,
      now: now,
      place: place)

    if pausedAnyTrip {
      LiveActivityManager.shared.end()
    }
  }

  func resumeAutoPausedTrips(at now: Date) {
    let place = locationManager.currentPlaceSummary
    let resumedTrip = AutoPauseCoordinator.resumeAutoPausedTrips(
      trips: &tripStore.trips,
      autoPausedTripIDs: &autoPausedTripIDs,
      now: now,
      place: place)

    if let resumedTrip {
      LiveActivityManager.shared.startActivity(
        tripName: resumedTrip.name,
        speedKmh: locationManager.speedKmh,
        distanceMeters: resumedTrip.distanceMeters,
        altitudeMeters: locationManager.altitudeMeters,
        useImperialUnits: useImperialUnits)
    }
  }
}

extension AnyTransition {
  static var glassGlimmer: AnyTransition {
    .modifier(
      active: GlassGlimmerAppearModifier(
        opacity: 0.0,
        scale: 0.88,
        blur: 8,
        highlightOpacity: 1.0),
      identity: GlassGlimmerAppearModifier(
        opacity: 1.0,
        scale: 1.0,
        blur: 0,
        highlightOpacity: 0.0))
  }
}
