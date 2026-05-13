//==============================================================
//  File: LiveActivityManager.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.80
//  Last Modified: 14/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines LiveActivityManager for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 14/05/2026 Add duration and average-speed payload fields, and enforce single Live Activity instance by reusing/deduping.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import ActivityKit
import Foundation

struct LiveActivitySnapshot {
  let tripName: String
  let speedKmh: Double
  let distanceMeters: Double
  let altitudeMeters: Double
  let durationSeconds: Double
  let averageSpeedKmh: Double
  let useImperialUnits: Bool
}

final class LiveActivityManager {
  static let shared = LiveActivityManager()

  private var activity: Activity<SpeedDemonActivityAttributes>?

  var hasActiveActivity: Bool {
    activity != nil
  }

  init() {
    let existing = Activity<SpeedDemonActivityAttributes>.activities.first
    if let existing {
      activity = existing
      print("🔄 Restored existing Live Activity with id: \(existing.id)")
    } else {
      print("ℹ️ No existing Live Activity to restore.")
    }
  }

  func startActivity(snapshot: LiveActivitySnapshot) {
    let authInfo = ActivityAuthorizationInfo()
    print("🔍 ActivityAuthorizationInfo =", authInfo)
    print("🔍 areActivitiesEnabled =", authInfo.areActivitiesEnabled)

    guard authInfo.areActivitiesEnabled else {
      print("⚠️ Live Activities are NOT enabled on this device/app.")
      return
    }

    let content = makeContent(from: snapshot)
    let existingActivities = Activity<SpeedDemonActivityAttributes>.activities

    if let primary = existingActivities.first {
      activity = primary
      Task {
        await activity?.update(content)
        await endDuplicateActivities(keeping: primary.id)
        print("ℹ️ Reused existing Live Activity and ended duplicates.")
      }
      return
    }

    let attributes = SpeedDemonActivityAttributes(id: UUID())

    do {
      let newActivity = try Activity.request(
        attributes: attributes,
        content: content,
        pushType: nil)
      activity = newActivity
      print("✅ Live Activity started with id:", newActivity.id)
    } catch {
      print("❌ Failed to start Live Activity: \(error)")
    }
  }

  func update(snapshot: LiveActivitySnapshot) {
    if activity == nil {
      activity = Activity<SpeedDemonActivityAttributes>.activities.first
    }

    guard let activity else {
      print("⚠️ Tried to update Live Activity, but none is active.")
      return
    }

    let content = makeContent(from: snapshot)

    Task {
      await activity.update(content)
      await endDuplicateActivities(keeping: activity.id)
      print("ℹ️ Live Activity updated.")
    }
  }

  func end() {
    let allActivities = Activity<SpeedDemonActivityAttributes>.activities
    guard !allActivities.isEmpty else {
      activity = nil
      print("ℹ️ end() called, but no activity to end.")
      return
    }

    Task {
      for activity in allActivities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      print("🛑 Ended all Live Activities.")
      self.activity = nil
    }
  }

  private func makeContent(from snapshot: LiveActivitySnapshot) -> ActivityContent<SpeedDemonActivityAttributes.ContentState> {
    let contentState = SpeedDemonActivityAttributes.ContentState(
      speedKmh: snapshot.speedKmh,
      distanceKm: snapshot.distanceMeters / 1000.0,
      tripName: snapshot.tripName,
      useImperialUnits: snapshot.useImperialUnits,
      altitudeMeters: snapshot.altitudeMeters,
      durationSeconds: snapshot.durationSeconds,
      averageSpeedKmh: snapshot.averageSpeedKmh)
    return ActivityContent(state: contentState, staleDate: nil)
  }

  private func endDuplicateActivities(keeping primaryID: String) async {
    for duplicate in Activity<SpeedDemonActivityAttributes>.activities where duplicate.id != primaryID {
      await duplicate.end(nil, dismissalPolicy: .immediate)
    }
  }
}
