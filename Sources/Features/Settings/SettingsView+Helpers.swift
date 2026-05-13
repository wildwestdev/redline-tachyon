//==============================================================
//  File: SettingsView+Helpers.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 13/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.76
//  Last Modified: 14/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Provides SettingsView helper rows and diagnostics properties to keep the main view type compact.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 13/05/2026 Extract diagnostics and row builders from SettingsView to satisfy type size and ordering lint rules.
//  Craig Little 13/05/2026 Add CoreLocation import for authorization/accuracy enum access in helper properties.
//  Craig Little 14/05/2026 Add app version/build and support issue URL helpers for Settings About section.
//  Craig Little 14/05/2026 Extract Settings About section view builder to reduce SettingsView type body length.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreLocation
import SwiftUI

extension SettingsView {
  var locationAuthorizationText: String {
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

  var accuracyAuthorizationDebugText: String {
    switch locationManager.accuracyAuthorization {
    case .fullAccuracy:
      "Full"
    case .reducedAccuracy:
      "Reduced"
    @unknown default:
      "Unknown"
    }
  }

  var carPlayConfigured: Bool {
    Bundle.main.object(forInfoDictionaryKey: "UISupportsCarPlay") as? Bool ?? false
  }

  var persistenceModeText: String {
    SwiftDataTripPersistence.shared.isUsingCloudKitSync
      ? "iCloud Sync (CloudKit private database)"
      : "Local-only fallback (CloudKit unavailable)"
  }

  var appVersionBuildText: String {
    let marketingVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    return "\(marketingVersion).\(buildNumber)"
  }

  var issueReporterURL: URL? {
    URL(string: "https://github.com/wildwestdev/speed-demon-support/issues/new/choose")
  }

  // MARK: - Reusable Glass Section Builder

  func aboutSection(openURL: OpenURLAction) -> some View {
    glassSection(title: "About") {
      Text("Version \(appVersionBuildText)")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(GlassTheme.primaryText)

      Button {
        guard let issueReporterURL else {
          return
        }
        openURL(issueReporterURL)
      } label: {
        Label("Report an issue", systemImage: "exclamationmark.bubble")
          .foregroundStyle(GlassTheme.primaryText)
      }
      .buttonStyle(GlassButtonStyle())
    }
  }

  func glassSection(
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

  func diagnosticsRow(title: String, value: String) -> some View {
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

  func thresholdStepperRow(
    title: String,
    valueText: String,
    value: Binding<Double>,
    range: ClosedRange<Double>,
    step: Double) -> some View
  {
    HStack(spacing: GlassTheme.Spacing.small) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .foregroundStyle(GlassTheme.primaryText)
        Text(valueText)
          .font(.caption)
          .foregroundStyle(GlassTheme.secondaryText)
      }

      Spacer(minLength: 0)

      Stepper("", value: value, in: range, step: step)
        .labelsHidden()
        .tint(GlassTheme.primaryText)
        .foregroundStyle(GlassTheme.primaryText)
    }
  }

  func thresholdStepperRow(
    title: String,
    valueText: String,
    value: Binding<Int>,
    range: ClosedRange<Int>,
    step: Int) -> some View
  {
    HStack(spacing: GlassTheme.Spacing.small) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .foregroundStyle(GlassTheme.primaryText)
        Text(valueText)
          .font(.caption)
          .foregroundStyle(GlassTheme.secondaryText)
      }

      Spacer(minLength: 0)

      Stepper("", value: value, in: range, step: step)
        .labelsHidden()
        .tint(GlassTheme.primaryText)
        .foregroundStyle(GlassTheme.primaryText)
    }
  }
}
