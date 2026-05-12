//==============================================================
//  File: GlassTextFieldModifier.swift
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
//    Defines GlassTextFieldModifier for the Speed Demon project.
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

struct GlassTextFieldModifier: ViewModifier {
  @FocusState private var isFocused: Bool

  func body(content: Content) -> some View {
    Group {
      if #available(iOS 26.0, *) {
        nativeTextField(content: content)
      } else {
        legacyTextField(content: content)
      }
    }
    .focused($isFocused)
  }

  private func nativeTextField(content: Content) -> some View {
    content
      .padding(.horizontal, GlassTheme.Spacing.small)
      .padding(.vertical, GlassTheme.Spacing.xSmall)
      .nativeGlassEffect(
        in: RoundedRectangle(cornerRadius: GlassTheme.Radius.medium, style: .continuous),
        tint: isFocused ? GlassTheme.ambientBottom.opacity(0.18) : nil,
        interactive: true)
      .overlay {
        RoundedRectangle(cornerRadius: GlassTheme.Radius.medium, style: .continuous)
          .stroke(
            Color.white.opacity(isFocused ? 0.18 : 0.08),
            lineWidth: isFocused ? 1.2 : 0.8)
      }
      .shadow(
        color: GlassTheme.Shadow.glass.opacity(0.5),
        radius: 10,
        x: 0,
        y: 6)
  }

  private func legacyTextField(content: Content) -> some View {
    content
      .padding(.horizontal, GlassTheme.Spacing.small)
      .padding(.vertical, GlassTheme.Spacing.xSmall)
      .background {
        RoundedRectangle(cornerRadius: GlassTheme.Radius.medium, style: .continuous)
          .fill(.regularMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: GlassTheme.Radius.medium, style: .continuous)
              .fill(
                LinearGradient(
                  colors: [
                    Color.white.opacity(0.28),
                    Color.white.opacity(0.05),
                    GlassTheme.ambientBottom.opacity(0.10)
                  ],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing))
              .blendMode(.screen)
          }
          .overlay {
            RoundedRectangle(cornerRadius: GlassTheme.Radius.medium, style: .continuous)
              .stroke(
                Color.white.opacity(isFocused ? 0.65 : 0.22),
                lineWidth: isFocused ? 1.4 : 1.0)
          }
          .overlay {
            RoundedRectangle(cornerRadius: GlassTheme.Radius.medium, style: .continuous)
              .stroke(
                GlassTheme.highlight.opacity(isFocused ? 0.85 : 0.45),
                lineWidth: isFocused ? 1.8 : 1.0)
          }
      }
      .shadow(
        color: GlassTheme.Shadow.glass,
        radius: 16,
        x: 0,
        y: 10)
      .shadow(
        color: GlassTheme.highlight.opacity(isFocused ? 0.5 : 0.0),
        radius: 12,
        x: 0,
        y: 0)
  }
}
