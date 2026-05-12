//==============================================================
//  File: TripTransferService.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 12/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.47
//  Last Modified: 12/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Provides JSON/CSV trip export, JSON import, and printable history text.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 12/05/2026 Add trip JSON/CSV export, JSON import, and print-history text formatting helpers.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct TripTransferEnvelope: Codable {
  let schemaVersion: Int
  let exportedAt: Date
  let trips: [Trip]
}

enum TripTransferService {
  static func exportJSONData(trips: [Trip]) throws -> Data {
    let envelope = TripTransferEnvelope(
      schemaVersion: 1,
      exportedAt: Date(),
      trips: trips)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(envelope)
  }

  static func exportCSVString(trips: [Trip]) -> String {
    var rows: [String] = []
    rows
      .append(
        "trip_id,trip_name,trip_distance_m,is_running,session_id,session_start,session_end,session_distance_m,session_start_location,session_end_location")

    let iso = ISO8601DateFormatter()

    for trip in trips {
      if trip.sessions.isEmpty {
        rows.append([
          csv(trip.id.uuidString),
          csv(trip.name),
          csv(String(format: "%.3f", trip.distanceMeters)),
          csv(trip.isRunning ? "true" : "false"),
          csv(""),
          csv(""),
          csv(""),
          csv(""),
          csv(trip.startLocationDescription ?? ""),
          csv(trip.endLocationDescription ?? "")
        ].joined(separator: ","))
        continue
      }

      for session in trip.sessions {
        rows.append([
          csv(trip.id.uuidString),
          csv(trip.name),
          csv(String(format: "%.3f", trip.distanceMeters)),
          csv(trip.isRunning ? "true" : "false"),
          csv(session.id.uuidString),
          csv(iso.string(from: session.startDate)),
          csv(session.endDate.map { iso.string(from: $0) } ?? ""),
          csv(String(format: "%.3f", session.distanceMeters)),
          csv(session.startLocationDescription ?? trip.startLocationDescription ?? ""),
          csv(session.endLocationDescription ?? trip.endLocationDescription ?? "")
        ].joined(separator: ","))
      }
    }

    return rows.joined(separator: "\n")
  }

  static func importTrips(from data: Data) throws -> [Trip] {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    if let envelope = try? decoder.decode(TripTransferEnvelope.self, from: data) {
      return envelope.trips
    }

    return try decoder.decode([Trip].self, from: data)
  }

  static func printableHistoryText(for trip: Trip, useImperialUnits: Bool) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short

    let title = trip.name.isEmpty ? "Trip History" : "\(trip.name) History"
    var lines: [String] = [title, ""]
    let ordered = trip.sessions.sorted { $0.startDate < $1.startDate }
    let distanceUnit = useImperialUnits ? "mi" : "km"
    let speedUnit = useImperialUnits ? "mph" : "km/h"

    for (index, session) in ordered.enumerated() {
      let baseKm = session.distanceKm
      let avgKmh = session.averageSpeedKmh
      let distance = useImperialUnits ? baseKm * 0.621371 : baseKm
      let avgSpeed = useImperialUnits ? avgKmh * 0.621371 : avgKmh
      let duration = formatDuration(session.duration)
      let start = formatter.string(from: session.startDate)
      let end = session.endDate.map { formatter.string(from: $0) } ?? "Running"

      lines.append("Session \(index + 1)")
      lines.append("Start: \(start)")
      lines.append("End: \(end)")
      lines.append(String(format: "Distance: %.3f %@", distance, distanceUnit))
      lines.append(String(format: "Average speed: %.1f %@", avgSpeed, speedUnit))
      lines.append("Duration: \(duration)")

      if let from = session.startLocationDescription ?? trip.startLocationDescription {
        lines.append("From: \(from)")
      }
      if let to = session.endLocationDescription ?? trip.endLocationDescription {
        lines.append("To: \(to)")
      }
      lines.append("")
    }

    if ordered.isEmpty {
      lines.append("No sessions recorded.")
    }

    return lines.joined(separator: "\n")
  }

  private static func csv(_ value: String) -> String {
    let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
  }

  private static func formatDuration(_ interval: TimeInterval) -> String {
    let total = max(0, Int(interval.rounded()))
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
  }
}

struct TripJSONDocument: FileDocument {
  static var readableContentTypes: [UTType] {
    [.json]
  }

  static var writableContentTypes: [UTType] {
    [.json]
  }

  let data: Data

  init(data: Data = Data()) {
    self.data = data
  }

  init(configuration: ReadConfiguration) throws {
    guard let fileData = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    data = fileData
  }

  func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}

struct TripCSVDocument: FileDocument {
  static var readableContentTypes: [UTType] {
    [.commaSeparatedText]
  }

  static var writableContentTypes: [UTType] {
    [.commaSeparatedText]
  }

  let text: String

  init(text: String = "") {
    self.text = text
  }

  init(configuration: ReadConfiguration) throws {
    guard
      let fileData = configuration.file.regularFileContents,
      let string = String(data: fileData, encoding: .utf8)
    else {
      throw CocoaError(.fileReadCorruptFile)
    }
    text = string
  }

  func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
    guard let data = text.data(using: .utf8) else {
      throw CocoaError(.fileWriteUnknown)
    }
    return FileWrapper(regularFileWithContents: data)
  }
}
