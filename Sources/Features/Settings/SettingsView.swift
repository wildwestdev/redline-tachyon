//==============================================================
//  File: SettingsView.swift
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
//    Defines SettingsView for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 12/05/2026 Add Sync Now plus trip export/import controls (JSON/CSV export, JSON import).
//  Craig Little 13/05/2026 Rename debug display section and motion toggle copy to reflect Motion + Sync status visibility.
//  Craig Little 13/05/2026 Narrow auto-pause wheel and align it beside the delay label/value for a tighter settings layout.
//  Craig Little 13/05/2026 Move GPS debug diagnostics directly under Debug Display toggle.
//  Craig Little 13/05/2026 Refresh GPS debug diagnostics every 5 seconds while Settings Debug Display is visible.
//  Craig Little 13/05/2026 Add customizable runtime thresholds for auto-pause speed and sync/debug refresh intervals.
//  Craig Little 13/05/2026 Simplify threshold controls to single-line steppers, style +/- controls white, and move debug GPS interval
//  into Debug Display section.
//  Craig Little 13/05/2026 Replace Auto Pause wheel picker with +/- stepper control for consistency.
//  Craig Little 13/05/2026 Broaden shared SettingsView helper-member scope for split-file access after build errors.
//  Craig Little 14/05/2026 Add version/build display and Report an issue button to Settings, and extract About section for lint body-size
//  compliance.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Combine
import CoreLocation
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
  @Binding var useImperialUnits: Bool
  @Binding var backgroundTrackingEnabled: Bool
  @Binding var displayMotion: Bool
  @Binding var autoPauseMinutes: Int
  @Binding var autoPauseMovingSpeedThresholdKmh: Double
  @Binding var syncSaveIntervalSeconds: Double
  @Binding var cloudRefreshIntervalSeconds: Double
  @Binding var debugGpsRefreshIntervalSeconds: Double

  @State private var justScheduledDisclaimer: Bool = false
  @State private var syncFeedbackText: String?
  @State private var isExportingJSON = false
  @State private var isExportingCSV = false
  @State private var isImportingJSON = false
  @State private var exportJSONDocument = TripJSONDocument()
  @State private var exportCSVDocument = TripCSVDocument()
  @State private var lastGpsDebugRefreshRequestAt: Date = .distantPast
  @Namespace private var glassNamespace
  @StateObject var locationManager = LocationManager.shared

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  var body: some View {
    NavigationStack {
      ZStack {
        GlassContainer(spacing: GlassTheme.Spacing.large) {
          ScrollView {
            VStack(alignment: .leading, spacing: GlassTheme.Spacing.large) {
              aboutSection(openURL: openURL)

              glassSection(title: "Units") {
                Toggle(isOn: $useImperialUnits) {
                  VStack(alignment: .leading) {
                    Text("Use Imperial Units")
                      .foregroundStyle(GlassTheme.primaryText)
                    Text("mph and miles instead of km/h and km")
                      .font(.caption)
                      .foregroundStyle(GlassTheme.secondaryText)
                  }
                }
                .toggleStyle(SwitchToggleStyle(tint: GlassTheme.ambientBottom))
              }

              glassSection(title: "Tracking") {
                Toggle(isOn: $backgroundTrackingEnabled) {
                  VStack(alignment: .leading) {
                    Text("Background Tracking")
                      .foregroundStyle(GlassTheme.primaryText)
                    Text("Continue updating trips when the app is in the background.")
                      .font(.caption)
                      .foregroundStyle(GlassTheme.secondaryText)
                  }
                }
                .toggleStyle(SwitchToggleStyle(tint: GlassTheme.ambientBottom))
              }

              glassSection(title: "Debug Display") {
                Toggle(isOn: $displayMotion) {
                  VStack(alignment: .leading) {
                    Text("Show Motion and Sync Status")
                      .foregroundStyle(GlassTheme.primaryText)
                    Text("Display the Motion and Sync debug status lines under the driving data panel.")
                      .font(.caption)
                      .foregroundStyle(GlassTheme.secondaryText)
                  }
                }
                .toggleStyle(SwitchToggleStyle(tint: GlassTheme.ambientBottom))

                #if DEBUG
                if displayMotion {
                  thresholdStepperRow(
                    title: "Debug GPS refresh interval",
                    valueText: "\(Int(debugGpsRefreshIntervalSeconds.rounded())) seconds",
                    value: $debugGpsRefreshIntervalSeconds,
                    range: 1 ... 30,
                    step: 1)

                  VStack(alignment: .leading, spacing: 2) {
                    Text("GPS auth: \(locationAuthorizationText)")
                    Text("GPS accuracy auth: \(accuracyAuthorizationDebugText)")
                    Text(String(format: "hAcc: %.1f m", locationManager.horizontalAccuracy))
                    Text(String(format: "vAcc: %.1f m", locationManager.verticalAccuracy))
                    Text(String(format: "speedAcc: %.2f m/s", locationManager.speedAccuracy))
                  }
                  .font(.caption2.monospacedDigit())
                  .foregroundStyle(GlassTheme.secondaryText)
                }
                #endif
              }

              glassSection(title: "Auto Pause") {
                thresholdStepperRow(
                  title: "Auto-pause delay",
                  valueText: autoPauseMinutes == 0
                    ? "Disabled"
                    : "\(autoPauseMinutes) minute\(autoPauseMinutes == 1 ? "" : "s")",
                  value: $autoPauseMinutes,
                  range: 0 ... 60,
                  step: 1)
              }

              glassSection(title: "Advanced Thresholds") {
                thresholdStepperRow(
                  title: "Auto-pause moving speed threshold",
                  valueText: String(format: "%.1f km/h", autoPauseMovingSpeedThresholdKmh),
                  value: $autoPauseMovingSpeedThresholdKmh,
                  range: 1 ... 10,
                  step: 0.5)

                thresholdStepperRow(
                  title: "Sync save interval",
                  valueText: "\(Int(syncSaveIntervalSeconds.rounded())) seconds",
                  value: $syncSaveIntervalSeconds,
                  range: 5 ... 120,
                  step: 5)

                thresholdStepperRow(
                  title: "Cloud refresh interval",
                  valueText: "\(Int(cloudRefreshIntervalSeconds.rounded())) seconds",
                  value: $cloudRefreshIntervalSeconds,
                  range: 2 ... 60,
                  step: 1)
              }

              glassSection(title: "Sync") {
                Button {
                  TripStore.shared.forceSyncNow()
                  syncFeedbackText = "Sync requested."
                } label: {
                  HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                      .font(.headline)
                    Text("Sync Now")
                      .font(.headline)
                  }
                  .foregroundStyle(GlassTheme.primaryText)
                }
                .buttonStyle(GlassButtonStyle())

                if let syncFeedbackText {
                  Text(syncFeedbackText)
                    .font(.caption)
                    .foregroundStyle(GlassTheme.secondaryText)
                }
              }

              glassSection(title: "Import / Export") {
                HStack(spacing: GlassTheme.Spacing.small) {
                  Button {
                    do {
                      let data = try TripTransferService.exportJSONData(trips: TripStore.shared.trips)
                      exportJSONDocument = TripJSONDocument(data: data)
                      isExportingJSON = true
                    } catch {
                      syncFeedbackText = "Export JSON failed."
                    }
                  } label: {
                    Label("Export JSON", systemImage: "square.and.arrow.up")
                      .foregroundStyle(GlassTheme.primaryText)
                  }
                  .buttonStyle(GlassButtonStyle())

                  Button {
                    exportCSVDocument = TripCSVDocument(
                      text: TripTransferService.exportCSVString(trips: TripStore.shared.trips))
                    isExportingCSV = true
                  } label: {
                    Label("Export CSV", systemImage: "tablecells.badge.ellipsis")
                      .foregroundStyle(GlassTheme.primaryText)
                  }
                  .buttonStyle(GlassButtonStyle())
                }

                Button {
                  isImportingJSON = true
                } label: {
                  Label("Import JSON", systemImage: "square.and.arrow.down")
                    .foregroundStyle(GlassTheme.primaryText)
                }
                .buttonStyle(GlassButtonStyle())
              }

              #if DEBUG
              glassSection(title: "Diagnostics") {
                diagnosticsRow(
                  title: "Location Authorization",
                  value: locationAuthorizationText)

                diagnosticsRow(
                  title: "Background Tracking",
                  value: backgroundTrackingEnabled ? "Enabled" : "Disabled")

                diagnosticsRow(
                  title: "CarPlay",
                  value: carPlayConfigured ? "Configured" : "Not Configured")

                diagnosticsRow(
                  title: "Persistence",
                  value: persistenceModeText)
              }
              #endif

              #if DEBUG || SHOW_DISCLAIMER_TEST_TOGGLE
              glassSection(title: "Testing") {
                Button {
                  UserDefaults.standard.set(true, forKey: "forceDisclaimerNextLaunch")
                  justScheduledDisclaimer = true
                } label: {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Show Disclaimer on Next Launch")
                      .font(.headline)

                    Text("For testing only — forces the splash disclaimer to appear the next time the app starts.")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                  .padding(.vertical, 4)
                }

                if justScheduledDisclaimer {
                  Text("✔️ The disclaimer will be shown on the next launch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
              #endif
            }
            .padding(.horizontal, GlassTheme.Spacing.medium)
            .padding(.top, GlassTheme.Spacing.medium)
            .padding(.bottom, GlassTheme.Spacing.large)
          }
        }
      }
      .glassBackground()
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.clear, for: .navigationBar)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("Settings")
            .font(.largeTitle.bold())
            .foregroundStyle(GlassTheme.primaryText)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .font(.headline)
              .foregroundStyle(GlassTheme.primaryText)
          }
          .buttonStyle(.glassCircleSmall)
          .nativeGlassMotion(id: "toolbar-close", in: glassNamespace)
        }
      }
    }
    .fileExporter(
      isPresented: $isExportingJSON,
      document: exportJSONDocument,
      contentType: .json,
      defaultFilename: "speed-demon-trips")
    { result in
      switch result {
      case .success:
        syncFeedbackText = "JSON exported."
      case .failure:
        syncFeedbackText = "Export JSON failed."
      }
    }
    .fileExporter(
      isPresented: $isExportingCSV,
      document: exportCSVDocument,
      contentType: .commaSeparatedText,
      defaultFilename: "speed-demon-trips")
    { result in
      switch result {
      case .success:
        syncFeedbackText = "CSV exported."
      case .failure:
        syncFeedbackText = "Export CSV failed."
      }
    }
    .fileImporter(
      isPresented: $isImportingJSON,
      allowedContentTypes: [.json],
      allowsMultipleSelection: false)
    { result in
      switch result {
      case .success(let urls):
        guard let url = urls.first else {
          syncFeedbackText = "Import cancelled."
          return
        }

        do {
          let data = try Data(contentsOf: url)
          let importedTrips = try TripTransferService.importTrips(from: data)
          TripStore.shared.replaceAllTrips(importedTrips)
          TripStore.shared.forceSyncNow()
          syncFeedbackText = "Imported \(importedTrips.count) trips."
        } catch {
          syncFeedbackText = "Import JSON failed."
        }
      case .failure:
        syncFeedbackText = "Import JSON failed."
      }
    }
    .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
      #if DEBUG
      if displayMotion {
        let interval = max(1, debugGpsRefreshIntervalSeconds)
        if now.timeIntervalSince(lastGpsDebugRefreshRequestAt) >= interval {
          locationManager.requestOneShotLocationUpdate()
          lastGpsDebugRefreshRequestAt = now
        }
      }
      #endif
    }
  }
}

#Preview {
  SettingsView(
    useImperialUnits: .constant(false),
    backgroundTrackingEnabled: .constant(true),
    displayMotion: .constant(true),
    autoPauseMinutes: .constant(1),
    autoPauseMovingSpeedThresholdKmh: .constant(3),
    syncSaveIntervalSeconds: .constant(30),
    cloudRefreshIntervalSeconds: .constant(5),
    debugGpsRefreshIntervalSeconds: .constant(5))
}
