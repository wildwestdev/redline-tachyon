//==============================================================
//  File: ContentView+TripUIAndLogic.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 13/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.68
//  Last Modified: 13/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Moves trip card UI and local speed/trip update helpers out of ContentView for lint-size compliance.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 13/05/2026 Extract trip UI and logic helpers from ContentView to reduce file and type body size.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import SwiftUI

extension ContentView {
  // MARK: - Trip UI

  // swiftlint:disable:next function_body_length
  func tripCard(trip: Binding<Trip>, useImperialUnits: Bool) -> some View {
    let tripID = trip.wrappedValue.id.uuidString

    return VStack(alignment: .leading, spacing: GlassTheme.Spacing.small) {
      HStack(spacing: GlassTheme.Spacing.small) {
        TextField("Trip name", text: trip.name)
          .font(.headline)
          .foregroundStyle(GlassTheme.primaryText)
          .glassTextFieldStyle()
          .frame(maxWidth: .infinity, alignment: .leading)

        GlassContainer(spacing: GlassTheme.Spacing.small) {
          HStack(spacing: GlassTheme.Spacing.small) {
            Button {
              if trip.isRunning.wrappedValue {
                trip.isRunning.wrappedValue = false

                if let openIndex = trip.sessions.wrappedValue.lastIndex(where: { $0.endDate == nil }) {
                  trip.sessions.wrappedValue[openIndex].endDate = Date()
                  let place = locationManager.currentPlaceSummary
                  if !place.isEmpty {
                    trip.sessions.wrappedValue[openIndex].endLocationDescription = place
                    trip.wrappedValue.endLocationDescription = place
                  }
                }

                LiveActivityManager.shared.end()
              } else {
                trip.isRunning.wrappedValue = true
                let place = locationManager.currentPlaceSummary
                let newSession = TripSession(
                  startDate: Date(),
                  startLocationDescription: place.isEmpty ? nil : place)
                trip.sessions.wrappedValue.append(newSession)

                if !place.isEmpty {
                  trip.wrappedValue.startLocationDescription = place
                }

                LiveActivityManager.shared.startActivity(
                  tripName: trip.wrappedValue.name,
                  speedKmh: 0,
                  distanceMeters: trip.wrappedValue.distanceMeters,
                  altitudeMeters: locationManager.altitudeMeters,
                  useImperialUnits: useImperialUnits)
              }
            } label: {
              Image(systemName: trip.isRunning.wrappedValue ? "pause.fill" : "play.fill")
                .font(.headline)
                .foregroundStyle(GlassTheme.primaryText)
            }
            .buttonStyle(GlassButtonStyle())
            .nativeGlassMotion(id: "trip-action-play-\(tripID)", in: glassNamespace)

            Button(role: .destructive) {
              let now = Date()
              let place = locationManager.currentPlaceSummary
              let isRunning = trip.isRunning.wrappedValue
              trip.distanceMeters.wrappedValue = 0

              if isRunning {
                if let openIndex = trip.sessions.wrappedValue.lastIndex(where: { $0.endDate == nil }) {
                  let existing = trip.sessions.wrappedValue[openIndex]
                  let startDescription = place.isEmpty ? existing.startLocationDescription : place
                  trip.sessions.wrappedValue[openIndex] = TripSession(
                    id: existing.id,
                    startDate: now,
                    endDate: nil,
                    distanceMeters: 0,
                    startLocationDescription: startDescription,
                    endLocationDescription: nil)
                } else {
                  trip.sessions.wrappedValue.append(
                    TripSession(
                      startDate: now,
                      startLocationDescription: place.isEmpty ? nil : place))
                }

                if !place.isEmpty {
                  trip.wrappedValue.startLocationDescription = place
                  trip.wrappedValue.endLocationDescription = nil
                }

                LiveActivityManager.shared.update(
                  speedKmh: locationManager.speedKmh,
                  distanceMeters: 0,
                  altitudeMeters: locationManager.altitudeMeters,
                  tripName: trip.wrappedValue.name,
                  useImperialUnits: useImperialUnits)
              } else if let lastIndex = trip.sessions.wrappedValue.indices.last {
                let existing = trip.sessions.wrappedValue[lastIndex]
                trip.sessions.wrappedValue[lastIndex] = TripSession(
                  id: existing.id,
                  startDate: existing.startDate,
                  endDate: existing.startDate,
                  distanceMeters: 0,
                  startLocationDescription: existing.startLocationDescription,
                  endLocationDescription: existing.endLocationDescription)
              }
            } label: {
              Image(systemName: "arrow.counterclockwise")
                .font(.headline)
                .foregroundStyle(GlassTheme.primaryText)
            }
            .buttonStyle(GlassButtonStyle())
            .nativeGlassMotion(id: "trip-action-reset-\(tripID)", in: glassNamespace)

            NavigationLink(destination: TripHistoryView(trip: trip)) {
              Image(systemName: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(GlassTheme.primaryText)
            }
            .buttonStyle(GlassButtonStyle())
            .nativeGlassMotion(id: "trip-action-history-\(tripID)", in: glassNamespace)

            Button {
              tripToDeleteID = trip.wrappedValue.id
              showDeleteAlert = true
            } label: {
              Image(systemName: "trash")
                .font(.headline)
                .foregroundStyle(.red)
            }
            .buttonStyle(GlassButtonStyle())
            .nativeGlassMotion(id: "trip-action-delete-\(tripID)", in: glassNamespace)
          }
          .nativeGlassMotion(id: "trip-actions-\(tripID)", in: glassNamespace)
        }
      }

      HStack {
        Text("Distance:")
          .font(.subheadline)
          .foregroundStyle(GlassTheme.secondaryText)

        let baseKm = trip.distanceMeters.wrappedValue / 1000.0
        let distance = useImperialUnits ? baseKm * 0.621371 : baseKm
        let unitLabel = useImperialUnits ? "mi" : "km"

        Text(String(format: "%.3f %@", distance, unitLabel))
          .font(.title3.monospacedDigit())
          .foregroundStyle(GlassTheme.primaryText)
      }

      tripHealthStrip(trip: trip.wrappedValue, useImperialUnits: useImperialUnits)
    }
    .glassCard(
      cornerRadius: GlassTheme.Radius.medium,
      opacity: GlassTheme.Glass.cardOpacity)
    .nativeGlassMotion(id: trip.wrappedValue.id, in: glassNamespace)
  }

  func tripHealthStrip(trip: Trip, useImperialUnits: Bool) -> some View {
    let totalDurationSeconds = trip.sessions.reduce(0.0) { $0 + $1.duration }
    let totalHours = totalDurationSeconds / 3600.0
    let averageSpeedKmh = totalHours > 0 ? (trip.distanceMeters / 1000.0) / totalHours : 0
    let averageSpeed = useImperialUnits ? averageSpeedKmh * 0.621371 : averageSpeedKmh
    let speedUnitLabel = useImperialUnits ? "mph" : "km/h"

    return HStack(spacing: GlassTheme.Spacing.small) {
      Label(formatDuration(totalDurationSeconds), systemImage: "clock")
      Spacer()
      Label(
        String(format: "Avg %.1f %@", averageSpeed, speedUnitLabel),
        systemImage: "gauge.with.needle")
      Spacer()
      Label("\(trip.sessions.count) session\(trip.sessions.count == 1 ? "" : "s")", systemImage: "list.bullet")
    }
    .font(.caption)
    .foregroundStyle(GlassTheme.secondaryText)
  }

  func formatDuration(_ timeInterval: TimeInterval) -> String {
    let totalSeconds = max(0, Int(timeInterval.rounded()))
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60

    if hours > 0 {
      return String(format: "%dh %02dm", hours, minutes)
    }

    return String(format: "%dm", minutes)
  }

  func cardinalDirection(from degrees: Double) -> String {
    let angle = (degrees.truncatingRemainder(dividingBy: 360) + 360)
      .truncatingRemainder(dividingBy: 360)

    if angle >= 338 || angle <= 23 { return "N" } else if angle <= 68 { return "NE" } else if angle <= 113 { return "E" }
    else if angle <= 158 { return "SE" } else if angle <= 203 { return "S" } else if angle <= 248 { return "SW" }
    else if angle <= 293 { return "W" } else { return "NW" }
  }

  func updateAcceleration(with newSpeedKmh: Double) {
    let now = Date()

    if newSpeedKmh == 0 || !locationManager.isLikelyMoving {
      accelerationMps2 = 0
      lastSpeedForAccel = 0
      lastSpeedSampleTime = now
      return
    }

    if let lastTime = lastSpeedSampleTime {
      let dt = now.timeIntervalSince(lastTime)
      guard dt > 0.1 else {
        lastSpeedSampleTime = now
        lastSpeedForAccel = newSpeedKmh
        return
      }

      let dvKmh = newSpeedKmh - lastSpeedForAccel
      let dvMps = dvKmh * (1000.0 / 3600.0)
      let rawAccel = dvMps / dt
      let clamped = max(-8.0, min(8.0, rawAccel))
      let smoothing = 0.7
      accelerationMps2 = accelerationMps2 * smoothing + clamped * (1 - smoothing)
    }

    lastSpeedSampleTime = now
    lastSpeedForAccel = newSpeedKmh
  }

  // MARK: - Logic

  func addTrip() {
    let newName = "Trip \(tripStore.trips.count + 1)"
    tripStore.trips.append(Trip(name: newName))
  }

  func updateTrips(with delta: Double) {
    guard delta > 0 else {
      return
    }

    let now = Date()

    for idx in tripStore.trips.indices {
      guard tripStore.trips[idx].isRunning else {
        continue
      }

      tripStore.trips[idx].distanceMeters += delta

      if let openIndex = tripStore.trips[idx].sessions.lastIndex(where: { $0.endDate == nil }) {
        tripStore.trips[idx].sessions[openIndex].distanceMeters += delta
      } else {
        let newSession = TripSession(startDate: now, distanceMeters: delta)
        tripStore.trips[idx].sessions.append(newSession)
      }
    }

    if let activeTrip = tripStore.trips.first(where: { $0.isRunning }) {
      LiveActivityManager.shared.update(
        speedKmh: locationManager.speedKmh,
        distanceMeters: activeTrip.distanceMeters,
        altitudeMeters: locationManager.altitudeMeters,
        tripName: activeTrip.name,
        useImperialUnits: useImperialUnits)
    }

    let anyRunning = tripStore.trips.contains(where: \.isRunning)
    if !anyRunning {
      LiveActivityManager.shared.end()
    }
  }
}
