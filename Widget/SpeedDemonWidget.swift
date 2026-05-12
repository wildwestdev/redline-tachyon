//==============================================================
//  File: SpeedDemonWidget.swift
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
//    Defines SpeedDemonWidget for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Shared Model

struct SpeedDemonEntry: TimelineEntry {
  let date: Date
  let speedKmh: Double
  let distanceKm: Double
  let isTripRunning: Bool
}

// MARK: - App Intent (for future interactivity)

@available(iOSApplicationExtension 17.0, *) struct OpenSpeedDemonIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Open Speed Demon"
  static let description = IntentDescription("Open Speed Demon to the main dashboard.")

  /// iOS will foreground the app when this runs
  static var openAppWhenRun: Bool {
    true
  }

  static var isDiscoverable: Bool {
    false
  }

  func perform() async throws -> some IntentResult {
    // You can add logging or analytics here if you like.
    .result()
  }
}

// Optional: later you can add intents like StartTripIntent / PauseTripIntent
// and call them from AppIntentButtons in the widget.

// MARK: - Provider using modern style

@available(iOSApplicationExtension 17.0, *) struct SpeedDemonProvider: AppIntentTimelineProvider {
  typealias Entry = SpeedDemonEntry
  typealias Intent = OpenSpeedDemonIntent

  func placeholder(in context: Context) -> Entry {
    SpeedDemonEntry(
      date: Date(),
      speedKmh: 72,
      distanceKm: 12.345,
      isTripRunning: true)
  }

  func snapshot(for configuration: Intent, in context: Context) async -> Entry {
    // For the widget gallery / quick snapshots
    placeholder(in: context)
  }

  func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
    // TODO: Replace this with real data loading from an app group or shared store.
    // For now we just generate a simple static timeline entry.

    let entry = SpeedDemonEntry(
      date: Date(),
      speedKmh: 0,
      distanceKm: 0,
      isTripRunning: false)

    // Refresh in 1 minute so the widget stays reasonably up to date.
    let nextUpdate =
      Calendar.current.date(byAdding: .minute, value: 1, to: Date())
        ?? Date().addingTimeInterval(60)

    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }
}

// MARK: - Widget View

struct SpeedDemonWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: SpeedDemonEntry

  var body: some View {
    content
      .padding(12)
      // System-provided glass tile that samples wallpaper
      .containerBackground(for: .widget) {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(.ultraThinMaterial.opacity(0.55)) // more transparent
      }
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(
            LinearGradient(
              colors: [
                Color.white.opacity(0.45),
                Color.white.opacity(0.08)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing),
            lineWidth: 1.0))
      // Tiny “glimmer” sweep that animates when the entry changes
      .overlay(glimmerOverlay)
      .shadow(color: Color.black.opacity(0.15), radius: 9, x: 0, y: 6)
  }

  @ViewBuilder
  private var content: some View {
    switch family {
    case .systemSmall:
      smallLayout
    case .systemMedium, .systemLarge:
      mediumLayout
    default:
      smallLayout
    }
  }

  private var speedString: String {
    String(format: "%.1f", entry.speedKmh)
  }

  private var distanceString: String {
    String(format: "%.2f", entry.distanceKm)
  }

  /// A subtle diagonal “glimmer” that sweeps across the glass when
  /// the widget entry updates. Uses phaseAnimator so it runs once per
  /// refresh, keeping things lightweight and widget-friendly.
  private var glimmerOverlay: some View {
    GeometryReader { proxy in
      let size = proxy.size

      Rectangle()
        .fill(
          LinearGradient(
            colors: [
              Color.white.opacity(0.0),
              Color.white.opacity(0.45),
              Color.white.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom))
        .frame(width: size.width * 0.7)
        .rotationEffect(.degrees(30))
        .offset(x: -size.width)
        .phaseAnimator([0.0, 1.0], trigger: entry.date) { content, phase in
          content
            .offset(x: -size.width + phase * (size.width * 2.0))
        } animation: { _ in
          .easeOut(duration: 0.8)
        }
        .blendMode(.screen)
    }
    .allowsHitTesting(false)
    .clipped()
  }

  // MARK: - Layouts

  private var smallLayout: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Speed Demon")
        .font(.caption2)
        .foregroundStyle(.secondary)

      Text("\(speedString)")
        .font(.system(size: 42, weight: .bold, design: .rounded))
        .monospacedDigit()

      Text("km/h")
        .font(.footnote)
        .foregroundStyle(.secondary)

      Spacer()

      HStack {
        Label("\(distanceString) km", systemImage: "road.lane")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Spacer()

        if entry.isTripRunning {
          Image(systemName: "play.fill")
            .font(.caption2.bold())
            .foregroundStyle(.green)
        } else {
          Image(systemName: "pause.fill")
            .font(.caption2.bold())
            .foregroundStyle(.yellow)
        }
      }
    }
  }

  private var mediumLayout: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Current Speed")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("\(speedString)")
          .font(.system(size: 50, weight: .bold, design: .rounded))
          .monospacedDigit()

        Text("km/h")
          .font(.footnote)
          .foregroundStyle(.secondary)

        Spacer()

        Label("\(distanceString) km", systemImage: "road.lane")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 8) {
        Text(entry.isTripRunning ? "Trip Running" : "Trip Paused")
          .font(.caption2)
          .foregroundStyle(entry.isTripRunning ? .green : .secondary)

        // Visual call-to-action icon; the widget tap target is still handled
        // by the overall AppIntentConfiguration.
        Image(systemName: "speedometer")
          .font(.title3.bold())
          .foregroundStyle(.primary)
          .opacity(0.9)
      }
    }
  }
}

// MARK: - Widget Definition

struct SpeedDemonWidget: Widget {
  let kind: String = "SpeedDemonWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: OpenSpeedDemonIntent.self,
      provider: SpeedDemonProvider())
    { entry in
      SpeedDemonWidgetView(entry: entry)
    }
    .configurationDisplayName("Speed Demon")
    .description("Glance at your current speed and trip distance.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main struct SpeedDemonWidgets: WidgetBundle {
  let kind: String = "SpeedDemonWidget"

  var body: some Widget {
    SpeedDemonWidget()

    if #available(iOSApplicationExtension 16.2, *) {
      SpeedDemonLiveActivity()
    }
  }
}

// MARK: - Preview

struct SpeedDemonWidget_Previews: PreviewProvider {
  static var previews: some View {
    SpeedDemonWidgetView(
      entry: SpeedDemonEntry(
        date: Date(),
        speedKmh: 88.8,
        distanceKm: 42.21,
        isTripRunning: true))
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
