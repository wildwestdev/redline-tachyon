//==============================================================
//  File: SpeedDemonLiveActivity.swift
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
//    Defines SpeedDemonLiveActivity for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 14/05/2026 Add trip name to Live Activity title and render two-column metric layout for CarPlay value display.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 16.2, *) struct SpeedDemonLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: SpeedDemonActivityAttributes.self) { context in
      // 🔹 Lock screen / banner presentation
      ZStack {
        LinearGradient(
          colors: [
            Color.white.opacity(0.35),
            Color.blue.opacity(0.35)
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing)

        VStack(spacing: 4) {
          Text(context.state.tripName.isEmpty ? "Speed Demon" : "Speed Demon - \(context.state.tripName)")
            .font(.caption2)
            .foregroundStyle(.secondary)

          HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 2) {
              Text("Distance")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Text(distanceString(from: context))
                .font(.headline.monospacedDigit())
              Text("Speed")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Text(String(
                format: "%.1f %@",
                displaySpeed(from: context),
                context.state.useImperialUnits ? "mph" : "km/h"))
                .font(.title3.weight(.bold))
                .monospacedDigit()
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
              Text("Duration")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Text(durationString(from: context))
                .font(.headline.monospacedDigit())
              Text("Avg Speed")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Text(String(
                format: "%.1f %@",
                displayAverageSpeed(from: context),
                context.state.useImperialUnits ? "mph" : "km/h"))
                .font(.title3.weight(.bold))
                .monospacedDigit()
            }
          }
        }
        .padding()
      }
    } dynamicIsland: { context in
      DynamicIsland {
        // MARK: - Expanded regions

        DynamicIslandExpandedRegion(.leading) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Speed")
              .font(.caption2)
              .foregroundStyle(.secondary)

            Text(String(format: "%.0f", displaySpeed(from: context)))
              .font(.title2.bold())
              .monospacedDigit()
          }
        }

        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 2) {
            Text("Distance")
              .font(.caption2)
              .foregroundStyle(.secondary)

            Text(distanceString(from: context))
              .font(.headline.monospacedDigit())
          }
        }

        DynamicIslandExpandedRegion(.bottom) {
          Text(context.state.tripName.isEmpty ? "Trip in progress" : context.state.tripName)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      } compactLeading: {
        // Left side of compact island
        Text(String(format: "%.0f", displaySpeed(from: context)))
          .font(.caption.bold())
          .monospacedDigit()
      } compactTrailing: {
        // Right side of compact island
        Text(context.state.useImperialUnits ? "mph" : "km/h")
          .font(.caption2)
      } minimal: {
        // Tiny bubble version
        Image(systemName: "speedometer")
      }
    }
  }

  // MARK: - Helpers

  private func displaySpeed(from context: ActivityViewContext<SpeedDemonActivityAttributes>) -> Double {
    let kmh = context.state.speedKmh
    return context.state.useImperialUnits ? kmh * 0.621371 : kmh
  }

  private func distanceString(from context: ActivityViewContext<SpeedDemonActivityAttributes>) -> String {
    let baseKm = context.state.distanceKm
    let val = context.state.useImperialUnits ? baseKm * 0.621371 : baseKm
    let unit = context.state.useImperialUnits ? "mi" : "km"
    return String(format: "%.2f %@", val, unit)
  }

  private func displayAverageSpeed(from context: ActivityViewContext<SpeedDemonActivityAttributes>) -> Double {
    let kmh = context.state.averageSpeedKmh
    return context.state.useImperialUnits ? kmh * 0.621371 : kmh
  }

  private func durationString(from context: ActivityViewContext<SpeedDemonActivityAttributes>) -> String {
    let seconds = max(0, Int(context.state.durationSeconds.rounded()))
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let remainingSeconds = seconds % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    return String(format: "%d:%02d", minutes, remainingSeconds)
  }
}
