//==============================================================
//  File: LiveActivityManager.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.1
//  Last Modified: 11/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines LiveActivityManager for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import ActivityKit
import Foundation

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

  func startActivity(
    tripName: String,
    speedKmh: Double,
    distanceMeters: Double,
    altitudeMeters: Double,
    useImperialUnits: Bool)
  {
    let authInfo = ActivityAuthorizationInfo()
    print("🔍 ActivityAuthorizationInfo =", authInfo)
    print("🔍 areActivitiesEnabled =", authInfo.areActivitiesEnabled)

    guard authInfo.areActivitiesEnabled else {
      print("⚠️ Live Activities are NOT enabled on this device/app.")
      return
    }

    let attributes = SpeedDemonActivityAttributes(id: UUID())
    let contentState = SpeedDemonActivityAttributes.ContentState(
      speedKmh: speedKmh,
      distanceKm: distanceMeters / 1000.0,
      tripName: tripName,
      useImperialUnits: useImperialUnits,
      altitudeMeters: altitudeMeters)

    let content = ActivityContent(state: contentState, staleDate: nil)

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

  func update(
    speedKmh: Double,
    distanceMeters: Double,
    altitudeMeters: Double,
    tripName: String,
    useImperialUnits: Bool)
  {
    guard let activity else {
      print("⚠️ Tried to update Live Activity, but none is active.")
      return
    }

    let contentState = SpeedDemonActivityAttributes.ContentState(
      speedKmh: speedKmh,
      distanceKm: distanceMeters / 1000.0,
      tripName: tripName,
      useImperialUnits: useImperialUnits,
      altitudeMeters: altitudeMeters)

    let content = ActivityContent(state: contentState, staleDate: nil)

    Task {
      await activity.update(content)
      print("ℹ️ Live Activity updated.")
    }
  }

  func end() {
    guard let activity else {
      print("ℹ️ end() called, but no activity to end.")
      return
    }

    Task {
      await activity.end(nil, dismissalPolicy: .immediate)
      print("🛑 Live Activity ended.")
      self.activity = nil
    }
  }
}
