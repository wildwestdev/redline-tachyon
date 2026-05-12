//==============================================================
//  File: GlassContainer.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.1
//  Last Modified: 11/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines GlassContainer for the Speed Demon project.
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

/// Evaluates runtime conditions to decide when native iOS glass APIs should be enabled.
private enum NativeGlassRuntime {
  // MARK: - Availability

  /// Returns `true` when native glass effects are available and enabled for the current runtime.
  static var isEnabled: Bool {
    guard #available(iOS 26.0, *) else {
      return false
    }

    if UserDefaults.standard.bool(forKey: "enableNativeGlassOnDevice") {
      return true
    }

    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
  }
}

/// Applies native glass materials to an arbitrary shape with an optional tint and interaction mode.
struct NativeGlassEffectModifier<GlassShape: Shape>: ViewModifier {
  /// Shape used as the glass clipping region.
  let shape: GlassShape
  /// Optional tint color blended into the native glass effect.
  let tint: Color?
  /// Controls whether the native glass effect is interactive.
  let interactive: Bool

  // MARK: - ViewModifier

  /// Builds the modified content with native glass APIs when available.
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *), NativeGlassRuntime.isEnabled {
      nativeBody(content: content)
    } else {
      content
    }
  }

  /// Applies the native glass effect and transition to the supplied content.
  @available(iOS 26.0, *) private func nativeBody(content: Content) -> some View {
    content
      .glassEffect(configuredGlass(), in: shape)
      .glassEffectTransition(.materialize)
  }

  /// Configures a native `Glass` value with optional tint and interaction settings.
  @available(iOS 26.0, *) private func configuredGlass() -> Glass {
    var glass = Glass.regular

    if let tint {
      glass = glass.tint(tint)
    }

    return glass.interactive(interactive)
  }
}

/// Applies native matched-glass motion using a shared namespace and hashable identifier.
struct NativeGlassMotionModifier<ID: Hashable & Sendable>: ViewModifier {
  /// Stable identifier used for matched glass transitions.
  let id: ID
  /// Namespace that links matching source and destination glass elements.
  let namespace: Namespace.ID

  // MARK: - ViewModifier

  /// Builds the modified content with matched native glass transitions when available.
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *), NativeGlassRuntime.isEnabled {
      nativeBody(content: content)
    } else {
      content
    }
  }

  /// Applies native matched-geometry glass transitions to the supplied content.
  @available(iOS 26.0, *) private func nativeBody(content: Content) -> some View {
    content
      .glassEffectID(id, in: namespace)
      .glassEffectTransition(.matchedGeometry)
  }
}

/// Provides a compatibility wrapper that uses `GlassEffectContainer` on supported OS versions.
struct GlassContainer<Content: View>: View {
  /// Optional spacing forwarded to the native glass container.
  let spacing: CGFloat?
  /// Content builder rendered inside the container.
  @ViewBuilder let content: () -> Content

  // MARK: - View

  /// Builds the container body using native glass when available, with fallback to raw content.
  var body: some View {
    if #available(iOS 26.0, *), NativeGlassRuntime.isEnabled {
      nativeBody
    } else {
      content()
    }
  }

  /// Builds the native glass container variant for supported OS versions.
  @available(iOS 26.0, *)
  private var nativeBody: some View {
    GlassEffectContainer(spacing: spacing) {
      content()
    }
  }
}

// MARK: - View Helpers

extension View {
  /// Applies a native glass effect using the provided shape, tint, and interaction configuration.
  func nativeGlassEffect(
    in shape: some Shape,
    tint: Color? = nil,
    interactive: Bool = false) -> some View
  {
    modifier(
      NativeGlassEffectModifier(
        shape: shape,
        tint: tint,
        interactive: interactive))
  }

  /// Applies matched native glass motion using a stable ID and a shared namespace.
  func nativeGlassMotion<ID: Hashable & Sendable>(
    id: ID,
    in namespace: Namespace.ID) -> some View
  {
    modifier(
      NativeGlassMotionModifier(
        id: id,
        namespace: namespace))
  }
}
