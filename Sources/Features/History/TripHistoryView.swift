//==============================================================
//  File: TripHistoryView.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.52
//  Last Modified: 13/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines TripHistoryView for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 12/05/2026 Add print-history toolbar action using formatted trip session output.
//  Craig Little 13/05/2026 Print history via text formatter to avoid protected-document print pipeline errors.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import SwiftUI
import UIKit

struct TripHistoryView: View {
  @Binding var trip: Trip
  @AppStorage("useImperialUnits") private var useImperialUnits: Bool = false
  @Environment(\.dismiss) private var dismiss

  @State private var showClearHistoryAlert = false
  @State private var toastMessage: String?
  @State private var isToastVisible = false
  @Namespace private var glassNamespace

  private var sortedSessions: [TripSession] {
    trip.sessions.sorted { $0.startDate > $1.startDate }
  }

  var body: some View {
    ZStack {
      sessionList
      toastOverlay
    }
    .glassBackground()
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(.clear, for: .navigationBar)
    .toolbarBackground(.hidden, for: .navigationBar)
    .toolbar {
      toolbarLeading
      toolbarPrint
      toolbarTrailing
      toolbarTitle
    }
    .navigationBarBackButtonHidden(true)
    .alert("Clear all history?", isPresented: $showClearHistoryAlert) {
      Button("Delete All", role: .destructive) {
        withAnimation {
          trip.sessions.removeAll()
          trip.distanceMeters = 0
        }
        showToast("History cleared 🧹")
      }

      Button("Cancel", role: .cancel) { }
    } message: {
      Text("This will remove all recorded sessions for this trip.")
    }
  }

  private var sessionList: some View {
    GlassContainer(spacing: GlassTheme.Spacing.small) {
      List {
        if sortedSessions.isEmpty {
          Section {
            Text("No sessions recorded yet.")
              .foregroundStyle(GlassTheme.secondaryText)
          }
          .listRowBackground(Color.clear)
        } else {
          ForEach(sortedSessions) { session in
            sessionRow(session)
              .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                deleteAction(for: session)
                shareAction(for: session)
                exportAction(for: session)
              }
              .listRowInsets(
                EdgeInsets(
                  top: 0,
                  leading: GlassTheme.Spacing.medium,
                  bottom: GlassTheme.Spacing.xSmall,
                  trailing: GlassTheme.Spacing.medium))
              .listRowBackground(Color.clear)
          }
        }
      }
      .scrollContentBackground(.hidden)
      .listStyle(.plain)
    }
  }

  private var toastOverlay: some View {
    VStack {
      Spacer()

      if isToastVisible, let message = toastMessage {
        GlassToastView(message: message)
          .padding(.bottom, GlassTheme.Spacing.large)
      }
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isToastVisible)
  }

  private var toolbarLeading: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.headline)
          .foregroundStyle(GlassTheme.primaryText)
      }
      .buttonStyle(.glassCircleSmall)
      .nativeGlassMotion(id: "toolbar-back", in: glassNamespace)
    }
  }

  private var toolbarTrailing: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        showClearHistoryAlert = true
      } label: {
        Image(systemName: "trash")
          .font(.headline)
          .foregroundStyle(.red)
      }
      .buttonStyle(.glassCircleSmall)
      .nativeGlassMotion(id: "toolbar-trash", in: glassNamespace)
    }
  }

  private var toolbarPrint: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        printHistory()
      } label: {
        Image(systemName: "printer")
          .font(.headline)
          .foregroundStyle(GlassTheme.primaryText)
      }
      .buttonStyle(.glassCircleSmall)
      .nativeGlassMotion(id: "toolbar-print", in: glassNamespace)
    }
  }

  private var toolbarTitle: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      Text(trip.name.isEmpty ? "Trip History" : "\(trip.name) History")
        .font(.largeTitle.bold())
        .foregroundStyle(GlassTheme.primaryText)
    }
  }

  private func deleteAction(for session: TripSession) -> some View {
    Button(role: .destructive) {
      if let index = trip.sessions.firstIndex(where: { $0.id == session.id }) {
        _ = withAnimation {
          trip.sessions.remove(at: index)
        }
        showToast("Session deleted 🗑️")
      }
    } label: {
      Label("Delete", systemImage: "trash")
    }
    .tint(.red.opacity(0.9))
  }

  private func shareAction(for session: TripSession) -> some View {
    ShareLink(item: shareSummary(for: session)) {
      Label("Share", systemImage: "square.and.arrow.up")
    }
    .tint(GlassTheme.highlight.opacity(0.9))
  }

  private func exportAction(for session: TripSession) -> some View {
    Button {
      UIPasteboard.general.string = shareSummary(for: session)
      showToast("Session copied 📋")
    } label: {
      Label("Export", systemImage: "doc.text")
    }
    .tint(GlassTheme.backgroundEnd.opacity(0.85))
  }

  private func shareSummary(for session: TripSession) -> String {
    let baseKm = session.distanceKm
    let avgKmh = session.averageSpeedKmh

    let distance = useImperialUnits ? baseKm * 0.621371 : baseKm
    let avgSpeed = useImperialUnits ? avgKmh * 0.621371 : avgKmh

    let distanceUnit = useImperialUnits ? "mi" : "km"
    let speedUnit = useImperialUnits ? "mph" : "km/h"

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short

    let dateString = formatter.string(from: session.startDate)
    let distanceString = String(format: "%.3f", distance)
    let speedString = String(format: "%.1f", avgSpeed)

    return "Trip on \(dateString): Distance \(distanceString) \(distanceUnit), average speed \(speedString) \(speedUnit)."
  }

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

  private func printHistory() {
    let printableText = TripTransferService.printableHistoryText(
      for: trip,
      useImperialUnits: useImperialUnits)
    let printController = UIPrintInteractionController.shared
    let info = UIPrintInfo(dictionary: nil)
    info.outputType = .general
    info.jobName = trip.name.isEmpty ? "Trip History" : "\(trip.name) History"
    printController.printInfo = info
    printController.printingItem = nil
    printController.printingItems = nil
    let formatter = UISimpleTextPrintFormatter(text: printableText)
    formatter.startPage = 0
    printController.printFormatter = formatter
    printController.present(animated: true) { _, completed, error in
      if completed {
        showToast("Print started 🖨️")
      } else if error != nil {
        showToast("Print failed")
      }
    }
  }

  private func sessionRow(_ session: TripSession) -> some View {
    VStack(alignment: .leading, spacing: GlassTheme.Spacing.xSmall) {
      HStack {
        Text(session.startDate, style: .date)
          .foregroundStyle(GlassTheme.primaryText)

        Text(session.startDate, style: .time)
          .foregroundStyle(GlassTheme.secondaryText)
      }
      .font(.subheadline)

      let durationSeconds = session.duration
      let minutes = Int(durationSeconds) / 60
      let seconds = Int(durationSeconds) % 60

      Text(String(format: "Duration: %d:%02d", minutes, seconds))
        .font(.footnote)
        .foregroundStyle(GlassTheme.secondaryText)

      let baseKm = session.distanceKm
      let avgKmh = session.averageSpeedKmh
      let distance = useImperialUnits ? baseKm * 0.621371 : baseKm
      let avgSpeed = useImperialUnits ? avgKmh * 0.621371 : avgKmh
      let distanceUnit = useImperialUnits ? "mi" : "km"
      let speedUnit = useImperialUnits ? "mph" : "km/h"

      Text(String(format: "Distance: %.3f %@", distance, distanceUnit))
        .font(.body.monospacedDigit())
        .foregroundStyle(GlassTheme.primaryText)

      Text(String(format: "Average speed: %.1f %@", avgSpeed, speedUnit))
        .font(.footnote.monospacedDigit())
        .foregroundStyle(GlassTheme.secondaryText)

      if let start = session.startLocationDescription ?? trip.startLocationDescription,
         let end = session.endLocationDescription ?? trip.endLocationDescription
      {
        Text("From \(start) → \(end)")
          .font(.footnote)
          .foregroundStyle(GlassTheme.secondaryText)
          .lineLimit(2)
      } else if let start = session.startLocationDescription ?? trip.startLocationDescription {
        Text("From \(start)")
          .font(.footnote)
          .foregroundStyle(GlassTheme.secondaryText)
          .lineLimit(2)
      }
    }
    .padding(.vertical, GlassTheme.Spacing.xSmall)
    .glassCard(
      cornerRadius: GlassTheme.Radius.medium,
      opacity: GlassTheme.Glass.cardOpacity)
    .nativeGlassMotion(id: session.id, in: glassNamespace)
    .frame(maxWidth: .infinity, alignment: .leading)
    .listRowSeparator(.hidden)
  }
}

#Preview {
  NavigationStack {
    TripHistoryView(
      trip: .constant(
        Trip(
          name: "Sample Trip",
          distanceMeters: 12345,
          isRunning: false,
          sessions: [
            TripSession(
              startDate: Date().addingTimeInterval(-3600),
              endDate: Date(),
              distanceMeters: 8000)
          ])))
  }
}
