//==============================================================
//  File: GlassTheme.swift
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
//    Defines GlassTheme for the Speed Demon project.
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

/// Defines shared colors, spacing, radii, and material constants for the glass UI system.
public enum GlassTheme {
  // MARK: - Layout Tokens

  /// Defines the corner-radius scale used by glass surfaces.
  public enum Radius {
    /// Small corner radius for compact controls.
    public static let small: CGFloat = 14
    /// Medium corner radius for bars and small cards.
    public static let medium: CGFloat = 22
    /// Large corner radius for primary cards.
    public static let large: CGFloat = 32
    /// Extra-large corner radius for hero surfaces.
    public static let extraLarge: CGFloat = 40
  }

  /// Defines the spacing scale used in glass layouts.
  public enum Spacing {
    /// Extra-small spacing for tight vertical rhythm.
    public static let xSmall: CGFloat = 4
    /// Small spacing for compact control groups.
    public static let small: CGFloat = 8
    /// Medium spacing for standard control separation.
    public static let medium: CGFloat = 16
    /// Large spacing for section separation.
    public static let large: CGFloat = 24
    /// Extra-large spacing for prominent grouping.
    public static let xLarge: CGFloat = 32
  }

  // MARK: - Lighting Tokens

  /// Defines reusable shadow values for glass depth and highlights.
  public enum Shadow {
    /// Base drop shadow color for glass elevation.
    public static let glass = Color.black.opacity(0.16)
    /// Highlight shadow color for top-edge bloom.
    public static let highlight = Color.white.opacity(0.10)
    /// Default blur radius for elevated glass surfaces.
    public static let radius: CGFloat = 24
    /// Default Y-offset for elevated glass surfaces.
    public static let offsetY: CGFloat = 16
  }

  /// Defines material opacity and blur values for glass surfaces.
  public enum Glass {
    /// Default opacity used by card-like glass surfaces.
    public static let cardOpacity: CGFloat = 0.60
    /// Default opacity used by bar-like glass surfaces.
    public static let barOpacity: CGFloat = 0.72
    /// Default blur intensity used by glass materials.
    public static let blur: CGFloat = 32
    /// Default sheen intensity used by highlight overlays.
    public static let sheenOpacity: CGFloat = 0.36
  }

  // MARK: - Color Tokens

  /// Primary gradient start color for app backgrounds.
  public static let backgroundStart = Color(
    .sRGB,
    red: 0.10,
    green: 0.14,
    blue: 0.22,
    opacity: 1.0)

  /// Primary gradient end color for app backgrounds.
  public static let backgroundEnd = Color(
    .sRGB,
    red: 0.32,
    green: 0.52,
    blue: 0.76,
    opacity: 1.0)

  /// Top ambient tint used for glass glow accents.
  public static let ambientTop = Color(
    .sRGB,
    red: 0.92,
    green: 0.97,
    blue: 1.0,
    opacity: 0.38)

  /// Bottom ambient tint used for glass glow accents.
  public static let ambientBottom = Color(
    .sRGB,
    red: 0.40,
    green: 0.66,
    blue: 0.98,
    opacity: 0.22)

  /// Strong specular highlight color for glass rims.
  public static let highlight = Color.white.opacity(0.48)
  /// Soft specular highlight color for broad sheen.
  public static let highlightSoft = Color.white.opacity(0.18)
  /// Outline color used to define glass edges.
  public static let outline = Color.white.opacity(0.14)
  /// Secondary text color tuned for glass contrast.
  public static let secondaryText = Color.white.opacity(0.74)
  /// Primary text color for high-contrast labels.
  public static let primaryText = Color.white
}
