//==============================================================
//  File: GlassToastView.swift
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
//    Defines GlassToastView for the Speed Demon project.
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

struct GlassToastView: View {
  let message: String

  var body: some View {
    Text(message)
      .font(.subheadline.weight(.medium))
      .foregroundStyle(GlassTheme.primaryText)
      .padding(.horizontal, GlassTheme.Spacing.medium)
      .padding(.vertical, GlassTheme.Spacing.small)
      .glassSurface(
        Capsule(style: .continuous),
        material: .regularMaterial,
        shadowRadius: 16,
        shadowOffset: 8)
      .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}
