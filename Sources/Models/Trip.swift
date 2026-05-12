//==============================================================
//  File: Trip.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.0
//  Last Modified: 11/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines Trip for the Speed Demon project.
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

struct Trip: Identifiable, Codable {
  private enum CodingKeys: String, CodingKey {
    case id
    case name
    case distanceMeters
    case isRunning
    case sessions
  }

  let id: UUID
  var name: String
  var distanceMeters: Double
  var isRunning: Bool
  var sessions: [TripSession]
  var startLocationDescription: String?
  var endLocationDescription: String?

  var distanceKm: Double {
    distanceMeters / 1000.0
  }

  init(
    id: UUID = UUID(),
    name: String,
    distanceMeters: Double = 0,
    isRunning: Bool = true,
    sessions: [TripSession] = [])
  {
    self.id = id
    self.name = name
    self.distanceMeters = distanceMeters
    self.isRunning = isRunning
    self.sessions = sessions
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Trip"
    distanceMeters = try container.decodeIfPresent(Double.self, forKey: .distanceMeters) ?? 0
    isRunning = try container.decodeIfPresent(Bool.self, forKey: .isRunning) ?? false
    sessions = try container.decodeIfPresent([TripSession].self, forKey: .sessions) ?? []
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(distanceMeters, forKey: .distanceMeters)
    try container.encode(isRunning, forKey: .isRunning)
    try container.encode(sessions, forKey: .sessions)
  }
}
