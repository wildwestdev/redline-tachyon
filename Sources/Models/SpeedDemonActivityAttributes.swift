//==============================================================
//  File: SpeedDemonActivityAttributes.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.76
//  Last Modified: 14/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines SpeedDemonActivityAttributes for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 14/05/2026 Add duration and average speed fields for richer Live Activity and CarPlay presentation.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import ActivityKit
import Foundation

struct SpeedDemonActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var speedKmh: Double
    var distanceKm: Double
    var tripName: String
    var useImperialUnits: Bool
    var altitudeMeters: Double
    var durationSeconds: Double
    var averageSpeedKmh: Double
  }

  /// Static attributes (don’t change during the activity)
  var id: UUID
}
