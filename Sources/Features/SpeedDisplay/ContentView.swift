//==============================================================
//  File: ContentView.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.70
//  Last Modified: 13/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines ContentView for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 12/05/2026 Run 30-second active persistence, keep idle-lock behavior, and show sync status under motion.
//  Craig Little 13/05/2026 Make Reset preserve play/pause state and only reset current-session trip metrics.
//  Craig Little 13/05/2026 Top-align Alt and Motion/Sync status row to remove debug-status vertical gap before location text.
//  Craig Little 13/05/2026 Add DEBUG GPS diagnostics block (auth and accuracy values) under driving data when debug display is enabled.
//  Craig Little 13/05/2026 Move DEBUG GPS diagnostics block to Settings under Debug Display toggle.
//  Craig Little 13/05/2026 Wire customizable runtime thresholds from Settings into auto-pause and sync timer behavior.
//  Craig Little 13/05/2026 Broaden split-file helper access levels to internal scope to restore build after ContentView extraction.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Combine
import CoreLocation
import SwiftUI

// swiftlint:disable type_body_length

struct ContentView: View {
  @StateObject var locationManager = LocationManager.shared
  @StateObject var tripStore = TripStore.shared

  @AppStorage("useImperialUnits") var useImperialUnits: Bool = false
  @AppStorage("backgroundTrackingEnabled") private var backgroundTrackingEnabled: Bool = false
  @AppStorage("displayMotion") private var displayMotion: Bool = false
  @AppStorage("autoPauseMinutes") var autoPauseMinutes: Int = 1
  @AppStorage("autoPauseMovingSpeedThresholdKmh") var autoPauseMovingSpeedThresholdKmh: Double = 3
  @AppStorage("syncSaveIntervalSeconds") private var syncSaveIntervalSeconds: Double = 30
  @AppStorage("cloudRefreshIntervalSeconds") private var cloudRefreshIntervalSeconds: Double = 5
  @AppStorage("debugGpsRefreshIntervalSeconds") private var debugGpsRefreshIntervalSeconds: Double = 5

  @State private var showingSettings = false
  @State var showDeleteAlert = false
  @State var tripToDeleteID: UUID?

  // Toast messages
  @State private var toastMessage: String?
  @State private var isToastVisible = false

  // Acceleration variables
  @State var lastSpeedForAccel: Double = 0
  @State var lastSpeedSampleTime: Date?
  @State var accelerationMps2: Double = 0
  @State var stationarySince: Date?
  @State var autoPausedTripIDs: Set<UUID> = []
  @Namespace var glassNamespace

  /// Orientation hint
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    NavigationStack {
      ZStack {
        Group {
          if verticalSizeClass == .compact {
            // Likely LANDSCAPE on iPhone: speed left, trips right
            GlassContainer(spacing: GlassTheme.Spacing.medium) {
              HStack(spacing: GlassTheme.Spacing.medium) {
                speedSection
                  .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .top)
                  .padding(.top, GlassTheme.Spacing.medium)

                tripsSection
                  .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity)
              }
            }
            .padding(.horizontal, GlassTheme.Spacing.medium)
          } else {
            // PORTRAIT: stacked vertically
            GlassContainer(spacing: GlassTheme.Spacing.large) {
              VStack(spacing: GlassTheme.Spacing.large) {
                speedSection
                  .padding(.top, GlassTheme.Spacing.medium)

                tripsSection
              }
            }
            .padding(.horizontal, GlassTheme.Spacing.medium)
          }
        }

        // Toast overlay
        VStack {
          Spacer()

          if isToastVisible, let message = toastMessage {
            GlassToastView(message: message)
              .padding(.bottom, GlassTheme.Spacing.large)
          }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isToastVisible)
      }
      .glassBackground()
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.clear, for: .navigationBar)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("Speed Demon")
            .font(.largeTitle.bold())
            .foregroundStyle(GlassTheme.primaryText)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showingSettings = true
          } label: {
            Image(systemName: "gearshape")
              .font(.headline)
              .foregroundStyle(GlassTheme.primaryText)
          }
          .buttonStyle(.glassCircleSmall)
          .nativeGlassMotion(id: "toolbar-settings", in: glassNamespace)
        }
      }
      .alert("Delete this trip?", isPresented: $showDeleteAlert) {
        Button("Yes, erase it forever 🗑️", role: .destructive) {
          guard
            let id = tripToDeleteID,
            let index = tripStore.trips.firstIndex(where: { $0.id == id })
          else {
            return
          }

          if tripStore.trips[index].isRunning {
            LiveActivityManager.shared.end()
          }

          _ = withAnimation(
            .spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.2))
          {
            tripStore.trips.remove(at: index)
          }

          showToast("Trip deleted 🚗💨")
          tripToDeleteID = nil
        }

        Button("No, keep it 🚗", role: .cancel) {
          tripToDeleteID = nil
        }
      } message: {
        Text("Are you *sure* you want to send this trip to the great highway in the sky?")
      }
    }
    .sheet(isPresented: $showingSettings) {
      SettingsView(
        useImperialUnits: $useImperialUnits,
        backgroundTrackingEnabled: $backgroundTrackingEnabled,
        displayMotion: $displayMotion,
        autoPauseMinutes: $autoPauseMinutes,
        autoPauseMovingSpeedThresholdKmh: $autoPauseMovingSpeedThresholdKmh,
        syncSaveIntervalSeconds: $syncSaveIntervalSeconds,
        cloudRefreshIntervalSeconds: $cloudRefreshIntervalSeconds,
        debugGpsRefreshIntervalSeconds: $debugGpsRefreshIntervalSeconds)
    }
    .onReceive(locationManager.$stepDistance) { delta in
      updateTrips(with: delta)
    }
    .onAppear {
      tripStore.setPersistenceActive(true)
      tripStore.refreshFromPersistence()
      updateIdleLockState()

      if locationManager.authorizationStatus == .authorizedAlways ||
        locationManager.authorizationStatus == .authorizedWhenInUse
      {
        locationManager.start()
      }

      locationManager.setBackgroundTracking(enabled: backgroundTrackingEnabled)
      tripStore.applySyncTimingSettings(
        saveIntervalSeconds: syncSaveIntervalSeconds,
        cloudRefreshIntervalSeconds: cloudRefreshIntervalSeconds)
      restoreLiveActivityIfNeeded()
    }
    .onChange(of: backgroundTrackingEnabled) {
      locationManager.setBackgroundTracking(enabled: backgroundTrackingEnabled)
    }
    .onChange(of: locationManager.speedKmh) { _, newSpeed in
      updateAcceleration(with: newSpeed)
    }
    .onChange(of: syncSaveIntervalSeconds) { _, newValue in
      tripStore.applySyncTimingSettings(
        saveIntervalSeconds: newValue,
        cloudRefreshIntervalSeconds: cloudRefreshIntervalSeconds)
    }
    .onChange(of: cloudRefreshIntervalSeconds) { _, newValue in
      tripStore.applySyncTimingSettings(
        saveIntervalSeconds: syncSaveIntervalSeconds,
        cloudRefreshIntervalSeconds: newValue)
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active {
        tripStore.setPersistenceActive(true)
        tripStore.refreshFromPersistence()
        updateIdleLockState()
      } else {
        tripStore.setPersistenceActive(false)
        UIApplication.shared.isIdleTimerDisabled = false
      }
    }
    .onReceive(tripStore.$trips) { _ in
      updateIdleLockState()
    }
    .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
      evaluateAutoPauseResume(at: now)
    }
  }

  // MARK: - Speed + Heading Section

  private var speedSection: some View {
    VStack(alignment: .leading, spacing: GlassTheme.Spacing.medium) {
      // Title for the combined cluster
      Text("Driving Data")
        .font(.headline)
        .foregroundStyle(GlassTheme.secondaryText)

      HStack(alignment: .top, spacing: GlassTheme.Spacing.medium) {
        speedCard
          .frame(maxWidth: .infinity)
        headingCard
          .frame(maxWidth: .infinity)
      }
      .frame(maxWidth: .infinity, alignment: .center)

      // Secondary driving details under the gauges
      VStack(
        alignment: .leading,
        spacing: displayMotion ? 2 : GlassTheme.Spacing.xSmall)
      {
        accelerationBar

        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 2) {
            // Altitude
            let altValue = useImperialUnits
              ? locationManager.altitudeMeters * 3.28084
              : locationManager.altitudeMeters
            let altUnit = useImperialUnits ? "ft" : "m"

            Text(String(format: "Alt: %.0f %@", altValue, altUnit))
              .font(.footnote)
              .foregroundStyle(GlassTheme.secondaryText)

            // Location summary
            if !locationManager.currentPlaceSummary.isEmpty {
              Text(locationManager.currentPlaceSummary)
                .font(.footnote)
                .foregroundStyle(GlassTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            }
          }

          Spacer()

          if displayMotion {
            VStack(alignment: .trailing, spacing: 2) {
              if let motionStatusText = StatusLineFormatter.motionStatusText(
                displayMotion: displayMotion,
                isLikelyMoving: locationManager.isLikelyMoving)
              {
                Text(motionStatusText)
                  .font(.footnote)
                  .foregroundStyle(locationManager.isLikelyMoving ? .green : GlassTheme.secondaryText)
              }

              Text(StatusLineFormatter.syncStatusText(syncStatus: tripStore.syncStatus))
                .font(.footnote)
                .foregroundStyle(syncStatusColor)
            }
          }
        }

        if let error = locationManager.lastError {
          Text(error)
            .font(.footnote)
            .foregroundColor(.red)
            .multilineTextAlignment(.leading)
            .padding(.top, GlassTheme.Spacing.xSmall)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassCard()
  }

  private var speedCard: some View {
    VStack(alignment: .center, spacing: GlassTheme.Spacing.xSmall) {
      Text("Speed")
        .font(.caption.weight(.medium))
        .foregroundStyle(GlassTheme.secondaryText)
        .frame(maxWidth: .infinity, alignment: .center)

      let displaySpeed = useImperialUnits
        ? locationManager.speedKmh * 0.621371
        : locationManager.speedKmh
      let speedUnitLabel = useImperialUnits ? "mph" : "km/h"

      HStack(alignment: .firstTextBaseline, spacing: GlassTheme.Spacing.xSmall) {
        Text(String(format: "%.0f", displaySpeed))
          .font(.system(size: 52, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(GlassTheme.primaryText)
          .minimumScaleFactor(0.8)

        Text(speedUnitLabel)
          .font(.title3)
          .foregroundStyle(GlassTheme.secondaryText)
      }
      .frame(maxWidth: .infinity, alignment: .center)
    }
    .frame(maxWidth: .infinity, alignment: .center)
  }

  private var headingCard: some View {
    VStack(alignment: .center, spacing: GlassTheme.Spacing.xSmall) {
      Text("Heading")
        .font(.caption.weight(.medium))
        .foregroundStyle(GlassTheme.secondaryText)
        .frame(maxWidth: .infinity, alignment: .center)

      let rawHeading = locationManager.headingDegrees
      let normalized = (rawHeading.truncatingRemainder(dividingBy: 360) + 360)
        .truncatingRemainder(dividingBy: 360)
      let wholeDegrees = Int(normalized.rounded())

      let cardinal = cardinalDirection(from: normalized)

      HStack(alignment: .firstTextBaseline, spacing: GlassTheme.Spacing.xSmall) {
        Text("\(wholeDegrees)°")
          .font(.system(size: 32, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(GlassTheme.primaryText)

        Text(cardinal)
          .font(.title3.weight(.medium))
          .foregroundStyle(GlassTheme.primaryText)
      }
      .frame(maxWidth: .infinity, alignment: .center)

      Text("Cardinal heading")
        .font(.caption)
        .foregroundStyle(GlassTheme.secondaryText)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    .frame(maxWidth: .infinity, alignment: .center)
    .overlay(headingGlimmerOverlay)
  }

  private var syncStatusColor: Color {
    switch tripStore.syncStatus {
    case .cloudConnected:
      .green
    case .uploading:
      .yellow
    case .importing:
      .blue
    case .localFallback:
      .orange
    }
  }

  /// A subtle diagonal glimmer that sweeps across the heading card when
  /// the heading moves into a new quadrant. This keeps it playful but
  /// not constantly animating with every tiny heading change.
  private var headingGlimmerOverlay: some View {
    GeometryReader { proxy in
      let size = proxy.size

      // Use a coarse quantisation of the heading (e.g. quadrants) so the
      // animation only triggers occasionally as the user turns.
      let normalized = (
        (locationManager.headingDegrees.truncatingRemainder(dividingBy: 360) + 360)
          .truncatingRemainder(dividingBy: 360))
      let triggerPhase = Int(normalized / 90.0) // 0–3

      Rectangle()
        .fill(
          LinearGradient(
            colors: [
              Color.white.opacity(0.0),
              Color.white.opacity(0.40),
              Color.white.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom))
        .frame(width: size.width * 0.9)
        .rotationEffect(.degrees(30))
        .offset(x: -size.width)
        .phaseAnimator([0.0, 1.0], trigger: triggerPhase) { content, phase in
          content
            .offset(x: -size.width + phase * (size.width * 2.0))
        } animation: { _ in
          .easeOut(duration: 0.7)
        }
        .blendMode(.screen)
    }
    .allowsHitTesting(false)
    .clipped()
  }

  // MARK: - Acceleration section

  private var accelerationBar: some View {
    VStack(alignment: .leading, spacing: GlassTheme.Spacing.xSmall) {
      HStack {
        Text("Acceleration")
          .font(.footnote.weight(.medium))
          .foregroundStyle(GlassTheme.secondaryText)

        Spacer()

        Text(String(format: "%.2f m/s²", accelerationMps2))
          .font(.footnote.monospacedDigit())
          .foregroundStyle(GlassTheme.primaryText)
      }

      GeometryReader { geo in
        let width = geo.size.width
        let mid = width / 2
        let maxMagnitude = 4.0 // visual range in m/s²
        let fraction = max(-1.0, min(1.0, accelerationMps2 / maxMagnitude))
        let barWidth = abs(fraction) * mid

        ZStack {
          // Background track
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(GlassTheme.backgroundStart.opacity(0.25))

          // Center line (zero acceleration)
          Rectangle()
            .fill(GlassTheme.secondaryText.opacity(0.6))
            .frame(width: 1)

          // Filled bar for accel / brake
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(fraction >= 0
              ? Color.green.opacity(0.7)
              : Color.red.opacity(0.7))
            .frame(width: max(2, barWidth), height: geo.size.height)
            .offset(x: fraction * mid)
            .animation(.easeOut(duration: 0.25), value: accelerationMps2)
        }
      }
      .frame(height: 10)
    }
  }

  // MARK: - Trips Section

  private var tripsSection: some View {
    ScrollView {
      VStack(spacing: GlassTheme.Spacing.small) {
        ForEach($tripStore.trips) { $trip in
          tripCard(trip: $trip, useImperialUnits: useImperialUnits)
            .transition(
              .asymmetric(
                insertion: .glassGlimmer,
                removal: .move(edge: .top).combined(with: .opacity)))
        }
        .animation(
          .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2),
          value: tripStore.trips.count)

        Button {
          addTrip()
        } label: {
          Image(systemName: "plus.circle.fill")
            .font(.headline)
            .foregroundStyle(GlassTheme.primaryText)
        }
        .buttonStyle(GlassButtonStyle())
        .padding(.top, GlassTheme.Spacing.small)
        .padding(.bottom, GlassTheme.Spacing.medium)
      }
    }
  }

  // MARK: - Toast

  private func showToast(_ message: String, duration: TimeInterval = 2.0) {
    toastMessage = message
    withAnimation {
      isToastVisible = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
      withAnimation(.easeOut(duration: 0.3)) {
        isToastVisible = false
      }
    }
  }

  // MARK: - Live Activity

  /// Restore Live Activity for running trips
  private func restoreLiveActivityIfNeeded() {
    // Find the first running trip (you can refine this if you support multiple)
    guard let activeTrip = tripStore.trips.first(where: { $0.isRunning }) else {
      return
    }

    if LiveActivityManager.shared.hasActiveActivity {
      // Bring the restored activity in sync with current data
      LiveActivityManager.shared.update(
        speedKmh: locationManager.speedKmh,
        distanceMeters: activeTrip.distanceMeters,
        altitudeMeters: locationManager.altitudeMeters,
        tripName: activeTrip.name,
        useImperialUnits: useImperialUnits)
      print("🔄 Synced existing Live Activity with running trip:", activeTrip.name)
    } else {
      // No system activity exists (e.g. user force-quit app, which also kills Live Activities).
      // Start a fresh Live Activity for this running trip.
      LiveActivityManager.shared.startActivity(
        tripName: activeTrip.name,
        speedKmh: locationManager.speedKmh,
        distanceMeters: activeTrip.distanceMeters,
        altitudeMeters: locationManager.altitudeMeters,
        useImperialUnits: useImperialUnits)
      print("🚀 Started new Live Activity for running trip:", activeTrip.name)
    }
  }
}

// swiftlint:enable type_body_length

#Preview {
  ContentView()
}
