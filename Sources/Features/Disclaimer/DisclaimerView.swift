//==============================================================
//  File: DisclaimerView.swift
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
//    Defines DisclaimerView for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import SwiftUI

struct DisclaimerView: View {
  let onAcknowledge: () -> Void

  var body: some View {
    GlassContainer(spacing: GlassTheme.Spacing.large) {
      ScrollView {
        VStack(spacing: GlassTheme.Spacing.large) {
          headerSection

          disclaimerSection(
            title: "Accuracy Warning",
            body: """
            Speed Demon estimates your speed and distance using GPS, witchcraft, intuition,
            and the occasional educated guess. This means your numbers might be delayed,
            confused, or overly optimistic.

            Your vehicle's speedometer is the grown-up here. Treat Speed Demon as a polished
            companion display, not the final authority.
            """)

          disclaimerSection(
            title: "Legal Disclaimer",
            body: """
            Speed Demon is for fun and general awareness only. It is not a certified
            navigation or measurement instrument, and it is not a legal defence for anything.

            Any infringements, fines, points, lectures, or awkward conversations remain
            entirely your responsibility.
            """)

          acknowledgeButton

          Text("Please drive safely. Speed Demon wants you alive.")
            .font(.caption)
            .foregroundStyle(GlassTheme.secondaryText)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, GlassTheme.Spacing.medium)
        .padding(.vertical, 32)
      }
    }
    .glassBackground()
  }

  private var headerSection: some View {
    VStack(spacing: 12) {
      Image(systemName: "speedometer")
        .font(.system(size: 54, weight: .semibold))
        .foregroundStyle(
          LinearGradient(
            colors: [Color.white, GlassTheme.ambientTop, GlassTheme.ambientBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing))

      Text("Speed Demon")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
        .foregroundStyle(GlassTheme.primaryText)

      Text("Important Notice")
        .font(.headline)
        .foregroundStyle(GlassTheme.secondaryText)
    }
    .frame(maxWidth: .infinity)
    .glassCard(cornerRadius: GlassTheme.Radius.extraLarge, opacity: 0.8)
  }

  private var acknowledgeButton: some View {
    Button {
      onAcknowledge()
    } label: {
      HStack {
        Spacer()
        Text("I Understand")
          .font(.headline)
          .foregroundStyle(GlassTheme.primaryText)
        Spacer()
      }
      .padding(.vertical, 12)
    }
    .buttonStyle(.plain)
    .glassBar()
  }

  private func disclaimerSection(title: String, body: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)
        .foregroundStyle(GlassTheme.primaryText)

      Text(body)
        .font(.subheadline)
        .foregroundStyle(GlassTheme.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassCard(cornerRadius: GlassTheme.Radius.large, opacity: 0.76)
  }
}

#Preview {
  DisclaimerView { }
}
