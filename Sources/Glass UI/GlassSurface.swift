//==============================================================
//  File: GlassSurface.swift
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
//    Defines GlassSurface for the Speed Demon project.
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

struct GlassSurface<Shape: InsettableShape>: ViewModifier {
  let shape: Shape
  let material: Material
  let shadowRadius: CGFloat
  let shadowOffset: CGFloat
  let tint: Color?
  let interactive: Bool

  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      nativeSurface(content: content)
    } else {
      legacySurface(content: content)
    }
  }

  private func nativeSurface(content: Content) -> some View {
    content
      .nativeGlassEffect(in: shape, tint: tint, interactive: interactive)
      .shadow(
        color: GlassTheme.Shadow.glass.opacity(0.5),
        radius: shadowRadius * 0.55,
        x: 0,
        y: shadowOffset * 0.45)
  }

  // swiftlint:disable:next function_body_length
  private func legacySurface(content: Content) -> some View {
    content
      .background {
        shape
          .fill(material)
          .overlay {
            shape
              .fill(
                LinearGradient(
                  colors: [
                    GlassTheme.ambientTop.opacity(Double(GlassTheme.Glass.sheenOpacity)),
                    Color.white.opacity(0.08),
                    GlassTheme.ambientBottom.opacity(0.22)
                  ],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing))
              .blendMode(.screen)
          }
          .overlay {
            shape
              .strokeBorder(GlassTheme.outline, lineWidth: 0.8)
          }
          .overlay {
            shape
              .inset(by: 1)
              .strokeBorder(
                LinearGradient(
                  colors: [
                    GlassTheme.highlight,
                    GlassTheme.highlightSoft.opacity(0.35),
                    Color.white.opacity(0.02)
                  ],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing),
                lineWidth: 1)
          }
          .overlay(alignment: .top) {
            shape
              .inset(by: 1.5)
              .trim(from: 0.03, to: 0.62)
              .stroke(
                LinearGradient(
                  colors: [
                    Color.white.opacity(0.55),
                    Color.white.opacity(0.05)
                  ],
                  startPoint: .leading,
                  endPoint: .trailing),
                style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
              .blur(radius: 0.2)
          }
          .shadow(
            color: GlassTheme.Shadow.highlight,
            radius: 6,
            x: 0,
            y: -1)
          .shadow(
            color: GlassTheme.Shadow.glass,
            radius: shadowRadius,
            x: 0,
            y: shadowOffset)
      }
  }
}

extension View {
  func glassSurface(
    _ shape: some InsettableShape,
    material: Material = .ultraThinMaterial,
    shadowRadius: CGFloat = GlassTheme.Shadow.radius,
    shadowOffset: CGFloat = GlassTheme.Shadow.offsetY,
    tint: Color? = nil,
    interactive: Bool = false) -> some View
  {
    modifier(
      GlassSurface(
        shape: shape,
        material: material,
        shadowRadius: shadowRadius,
        shadowOffset: shadowOffset,
        tint: tint,
        interactive: interactive))
  }
}
