//==============================================================
//  File: GlassToggleStyle.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.11
//  Last Modified: 11/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines GlassToggleStyle for the Speed Demon project.
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

struct GlassToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label

      Spacer(minLength: GlassTheme.Spacing.medium)

      toggleTrack(configuration: configuration)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      configuration.isOn.toggle()
    }
  }

  private func toggleTrack(configuration: Configuration) -> some View {
    ZStack(alignment: configuration.isOn ? .trailing : .leading) {
      trackBackground(configuration: configuration)
      trackThumb(configuration: configuration)
    }
    .frame(width: 52, height: 30)
    .shadow(color: GlassTheme.Shadow.glass, radius: 10, x: 0, y: 6)
    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isOn)
    .accessibilityLabel(configuration.isOn ? "On" : "Off")
    .accessibilityAddTraits(.isButton)
  }

  @ViewBuilder private func trackBackground(configuration: Configuration) -> some View {
    if #available(iOS 26.0, *) {
      RoundedRectangle(cornerRadius: GlassTheme.Radius.large, style: .continuous)
        .fill(Color.clear)
        .nativeGlassEffect(
          in: RoundedRectangle(cornerRadius: GlassTheme.Radius.large, style: .continuous),
          tint: configuration.isOn ? GlassTheme.ambientBottom.opacity(0.22) : nil,
          interactive: true)
    } else {
      RoundedRectangle(cornerRadius: GlassTheme.Radius.large, style: .continuous)
        .fill(.regularMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: GlassTheme.Radius.large, style: .continuous)
            .fill(
              LinearGradient(
                colors: [
                  Color.white.opacity(0.16),
                  GlassTheme.ambientBottom.opacity(configuration.isOn ? 0.22 : 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing))
            .blendMode(.screen)
        }
        .overlay {
          RoundedRectangle(cornerRadius: GlassTheme.Radius.large, style: .continuous)
            .stroke(GlassTheme.outline, lineWidth: 0.8)
        }
        .overlay {
          RoundedRectangle(cornerRadius: GlassTheme.Radius.large, style: .continuous)
            .stroke(GlassTheme.highlight.opacity(0.55), lineWidth: 1)
        }
    }
  }

  private func trackThumb(configuration: Configuration) -> some View {
    Circle()
      .fill(Color.clear)
      .glassSurface(
        Circle(),
        material: .regularMaterial,
        shadowRadius: 8,
        shadowOffset: 4,
        tint: configuration.isOn ? GlassTheme.ambientBottom.opacity(0.28) : nil,
        interactive: true)
      .frame(width: 22, height: 22)
      .shadow(
        color: (configuration.isOn ? GlassTheme.ambientBottom : GlassTheme.highlight)
          .opacity(0.35),
        radius: 10,
        x: 0,
        y: 0)
      .padding(4)
  }
}
