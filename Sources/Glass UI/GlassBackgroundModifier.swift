//==============================================================
//  File: GlassBackgroundModifier.swift
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
//    Defines GlassBackgroundModifier for the Speed Demon project.
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

struct GlassBackgroundModifier: ViewModifier {
  private var backgroundLayers: some View {
    ZStack {
      LinearGradient(
        colors: [
          GlassTheme.backgroundStart,
          GlassTheme.backgroundEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing)

      RadialGradient(
        colors: [
          GlassTheme.ambientTop,
          Color.clear
        ],
        center: .topLeading,
        startRadius: 40,
        endRadius: 420)
        .blendMode(.screen)

      RadialGradient(
        colors: [
          GlassTheme.ambientBottom,
          Color.clear
        ],
        center: .bottomTrailing,
        startRadius: 40,
        endRadius: 460)
        .blendMode(.plusLighter)

      LinearGradient(
        colors: [
          Color.white.opacity(0.08),
          Color.clear,
          Color.black.opacity(0.14)
        ],
        startPoint: .top,
        endPoint: .bottom)
    }
    .ignoresSafeArea()
  }

  func body(content: Content) -> some View {
    content
      .background(backgroundLayers)
  }
}
