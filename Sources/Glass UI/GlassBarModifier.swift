//==============================================================
//  File: GlassBarModifier.swift
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
//    Defines GlassBarModifier for the Speed Demon project.
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

struct GlassBarModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(.vertical, GlassTheme.Spacing.small)
      .padding(.horizontal, GlassTheme.Spacing.medium)
      .glassSurface(
        RoundedRectangle(
          cornerRadius: GlassTheme.Radius.medium,
          style: .continuous),
        material: .regularMaterial,
        shadowRadius: 18,
        shadowOffset: 10,
        interactive: true)
  }
}
