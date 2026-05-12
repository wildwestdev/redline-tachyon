//==============================================================
//  File: GlassBackgroundStyle.swift
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
//    Defines GlassBackgroundStyle for the Speed Demon project.
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

/// Namespaces background style helpers for lint/file-name consistency.
private enum GlassBackgroundStyle { }

/// Adds convenience APIs for applying the app-wide glass background treatment.
public extension View {
  /// Applies the shared gradient and ambient glows used across glass screens.
  func glassBackground() -> some View {
    modifier(GlassBackgroundModifier())
  }
}
