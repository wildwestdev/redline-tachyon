//==============================================================
//  File: GlassCircleButtonStyle.swift
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
//    Defines GlassCircleButtonStyle for the Speed Demon project.
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

struct GlassCircleButtonStyle: ButtonStyle {
  var diameter: CGFloat = 34

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(width: diameter, height: diameter)
      .glassSurface(
        Circle(),
        material: .regularMaterial,
        shadowRadius: 16,
        shadowOffset: 8,
        tint: configuration.isPressed ? GlassTheme.ambientBottom.opacity(0.22) : nil,
        interactive: true)
      .overlay {
        Circle()
          .fill(
            LinearGradient(
              colors: [
                Color.white.opacity(configuration.isPressed ? 0.28 : 0.16),
                Color.clear,
                GlassTheme.ambientBottom.opacity(0.18)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing))
          .blendMode(.screen)
      }
      .shadow(
        color: GlassTheme.highlight.opacity(configuration.isPressed ? 0.4 : 0),
        radius: 10,
        x: 0,
        y: 0)
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == GlassCircleButtonStyle {
  static var glassCircle: GlassCircleButtonStyle {
    GlassCircleButtonStyle()
  }

  static var glassCircleSmall: GlassCircleButtonStyle {
    GlassCircleButtonStyle(diameter: 28)
  }

  static var glassCircleMini: GlassCircleButtonStyle {
    GlassCircleButtonStyle(diameter: 22)
  }
}
