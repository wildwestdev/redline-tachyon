//==============================================================
//  File: GlassCardModifier.swift
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
//    Defines GlassCardModifier for the Speed Demon project.
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

/// Applies standard glass-card padding, material, and shadow treatment to wrapped content.
public struct GlassCardModifier: ViewModifier {
  /// Controls the card corner radius used by the underlying rounded rectangle.
  public var cornerRadius: CGFloat
  /// Controls the card material opacity used to select regular vs thin material.
  public var opacity: CGFloat

  // MARK: - Initialization

  /// Creates a configurable glass-card modifier with optional radius and opacity overrides.
  public init(
    cornerRadius: CGFloat = GlassTheme.Radius.large,
    opacity: CGFloat = GlassTheme.Glass.cardOpacity)
  {
    self.cornerRadius = cornerRadius
    self.opacity = opacity
  }

  // MARK: - ViewModifier

  /// Builds the card body by applying padding and a rounded glass surface treatment.
  public func body(content: Content) -> some View {
    content
      .padding(GlassTheme.Spacing.medium)
      .glassSurface(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
        material: opacity > 0.65 ? .regularMaterial : .thinMaterial,
        shadowRadius: GlassTheme.Shadow.radius,
        shadowOffset: GlassTheme.Shadow.offsetY)
  }
}
