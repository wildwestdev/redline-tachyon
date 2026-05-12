//==============================================================
//  File: TripSession.swift
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
//    Defines TripSession for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct TripSession: Identifiable, Codable {
  let id: UUID
  let startDate: Date
  var endDate: Date?
  var distanceMeters: Double
  var startLocationDescription: String?
  var endLocationDescription: String?

  var duration: TimeInterval {
    let end = endDate ?? Date()
    return end.timeIntervalSince(startDate)
  }

  var distanceKm: Double {
    distanceMeters / 1000.0
  }

  var averageSpeedKmh: Double {
    let hours = duration / 3600.0

    guard hours > 0 else {
      return 0
    }

    return distanceKm / hours
  }

  init(
    id: UUID = UUID(),
    startDate: Date,
    endDate: Date? = nil,
    distanceMeters: Double = 0,
    startLocationDescription: String? = nil,
    endLocationDescription: String? = nil)
  {
    self.id = id
    self.startDate = startDate
    self.endDate = endDate
    self.distanceMeters = distanceMeters
    self.startLocationDescription = startLocationDescription
    self.endLocationDescription = endLocationDescription
  }
}
