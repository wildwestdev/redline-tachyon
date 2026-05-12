//==============================================================
//  File: GlassButtonStyle.swift
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
//    Defines GlassButtonStyle for the Speed Demon project.
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

struct GlassButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(12)
      .glassSurface(
        Circle(),
        material: .regularMaterial,
        shadowRadius: 18,
        shadowOffset: 10,
        tint: configuration.isPressed ? GlassTheme.ambientBottom.opacity(0.24) : nil,
        interactive: true)
      .overlay {
        Circle()
          .fill(
            AngularGradient(
              colors: [
                Color.white.opacity(configuration.isPressed ? 0.35 : 0.18),
                Color.clear,
                GlassTheme.ambientBottom.opacity(0.18),
                Color.clear,
                Color.white.opacity(configuration.isPressed ? 0.30 : 0.12)
              ],
              center: .center))
          .blendMode(.screen)
      }
      .shadow(
        color: GlassTheme.highlight.opacity(configuration.isPressed ? 0.55 : 0.0),
        radius: 14,
        x: 0,
        y: 0)
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .brightness(configuration.isPressed ? 0.04 : 0.0)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
  }
}
