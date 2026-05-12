//==============================================================
//  File: SettingsView.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.47
//  Last Modified: 12/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines SettingsView for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 12/05/2026 Add Sync Now plus trip export/import controls (JSON/CSV export, JSON import).
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreLocation
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
  @Binding var useImperialUnits: Bool
  @Binding var backgroundTrackingEnabled: Bool
  @Binding var displayMotion: Bool
  @Binding var autoPauseMinutes: Int

  @State private var justScheduledDisclaimer: Bool = false
  @State private var syncFeedbackText: String?
  @State private var isExportingJSON = false
  @State private var isExportingCSV = false
  @State private var isImportingJSON = false
  @State private var exportJSONDocument = TripJSONDocument()
  @State private var exportCSVDocument = TripCSVDocument()
  @Namespace private var glassNamespace
  @StateObject private var locationManager = LocationManager.shared

  @Environment(\.dismiss) private var dismiss

  private var locationAuthorizationText: String {
    switch locationManager.authorizationStatus {
    case .notDetermined:
      "Not Determined"
    case .restricted:
      "Restricted"
    case .denied:
      "Denied"
    case .authorizedWhenInUse:
      "When In Use"
    case .authorizedAlways:
      "Always"
    @unknown default:
      "Unknown"
    }
  }

  private var carPlayConfigured: Bool {
    Bundle.main.object(forInfoDictionaryKey: "UISupportsCarPlay") as? Bool ?? false
  }

  private var persistenceModeText: String {
    SwiftDataTripPersistence.shared.isUsingCloudKitSync
      ? "iCloud Sync (CloudKit private database)"
      : "Local-only fallback (CloudKit unavailable)"
  }

  var body: some View {
    NavigationStack {
      ZStack {
        GlassContainer(spacing: GlassTheme.Spacing.large) {
          ScrollView {
            VStack(alignment: .leading, spacing: GlassTheme.Spacing.large) {
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

              glassSection(title: "Debug / Motion") {
                Toggle(isOn: $displayMotion) {
                  VStack(alignment: .leading) {
                    Text("Display Motion")
                      .foregroundStyle(GlassTheme.primaryText)
                    Text("Show whether motion sensors think the vehicle is moving or still.")
                      .font(.caption)
                      .foregroundStyle(GlassTheme.secondaryText)
                  }
                }
                .toggleStyle(SwitchToggleStyle(tint: GlassTheme.ambientBottom))
              }

              glassSection(title: "Auto Pause") {
                VStack(alignment: .leading, spacing: GlassTheme.Spacing.xSmall) {
                  Text("Auto-pause delay")
                    .foregroundStyle(GlassTheme.primaryText)

                  Text(
                    autoPauseMinutes == 0
                      ? "Disabled"
                      : "\(autoPauseMinutes) minute\(autoPauseMinutes == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(GlassTheme.secondaryText)
                }

                Picker("Auto-pause minutes", selection: $autoPauseMinutes) {
                  ForEach(0 ... 60, id: \.self) { minute in
                    Text(minute == 0 ? "0 (Disabled)" : "\(minute)")
                      .tag(minute)
                  }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
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
  }

  // MARK: - Reusable Glass Section Builder

  private func glassSection(
    title: String,
    @ViewBuilder content: () -> some View) -> some View
  {
    VStack(alignment: .leading, spacing: GlassTheme.Spacing.small) {
      Text(title)
        .font(.headline)
        .foregroundStyle(GlassTheme.secondaryText)

      VStack(alignment: .leading, spacing: GlassTheme.Spacing.medium) {
        content()
      }
      .glassCard(
        cornerRadius: GlassTheme.Radius.medium,
        opacity: GlassTheme.Glass.cardOpacity)
    }
  }

  private func diagnosticsRow(title: String, value: String) -> some View {
    HStack(alignment: .top, spacing: GlassTheme.Spacing.small) {
      Text(title)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(GlassTheme.primaryText)

      Spacer()

      Text(value)
        .font(.subheadline)
        .foregroundStyle(GlassTheme.secondaryText)
        .multilineTextAlignment(.trailing)
    }
  }
}

#Preview {
  SettingsView(
    useImperialUnits: .constant(false),
    backgroundTrackingEnabled: .constant(true),
    displayMotion: .constant(true),
    autoPauseMinutes: .constant(1))
}
