//==============================================================
//  File: SpeedDemonApp.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.33
//  Last Modified: 12/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Defines app startup, permissions, and scene configuration including CarPlay.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 11/05/2026 Added CarPlay scene configuration via AppDelegate.
//  Craig Little 12/05/2026 Skip normal app startup side effects while unit tests run inside the host app.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//

import CarPlay
import SwiftUI
import UIKit
import UserNotifications

/// Selects scene delegates for app and CarPlay session roles.
final class SpeedDemonAppDelegate: NSObject, UIApplicationDelegate {
  /// Returns scene configuration for connected app or CarPlay sessions.
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions) -> UISceneConfiguration
  {
    let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)

    if connectingSceneSession.role == .carTemplateApplication {
      configuration.sceneClass = CPTemplateApplicationScene.self
      configuration.delegateClass = CarPlaySceneDelegate.self
    }

    return configuration
  }
}

@main struct SpeedDemonApp: App {
  @UIApplicationDelegateAdaptor(SpeedDemonAppDelegate.self)
  private var appDelegate

  @AppStorage("hasAcceptedSpeedDemonDisclaimer")
  private var hasAcceptedDisclaimer: Bool = false

  @AppStorage("forceDisclaimerNextLaunch")
  private var forceDisclaimerNextLaunch: Bool = false

  private let isRunningUnitTests: Bool

  /// This is evaluated once per cold launch.
  @State private var showDisclaimer: Bool

  /// Builds the primary device UI scene.
  var body: some Scene {
    WindowGroup {
      if isRunningUnitTests {
        EmptyView()
      } else if showDisclaimer {
        DisclaimerView {
          hasAcceptedDisclaimer = true
          showDisclaimer = false
        }
      } else {
        ContentView()
      }
    }
  }

  /// Initializes one-shot launch flags and permission bootstrap.
  init() {
    isRunningUnitTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    let defaults = UserDefaults.standard
    let accepted = defaults.bool(forKey: "hasAcceptedSpeedDemonDisclaimer")
    let forced = defaults.bool(forKey: "forceDisclaimerNextLaunch")

    _showDisclaimer = State(initialValue: !accepted || forced)

    if forced {
      defaults.set(false, forKey: "forceDisclaimerNextLaunch")
    }

    if !isRunningUnitTests {
      requestNotificationAuthorizationIfNeeded()
    }
  }

  /// Requests notification permission if the user has not made a choice yet.
  private func requestNotificationAuthorizationIfNeeded() {
    let center = UNUserNotificationCenter.current()

    center.getNotificationSettings { settings in
      guard settings.authorizationStatus == .notDetermined else {
        return
      }

      center.requestAuthorization(
        options: [.alert, .sound, .badge])
      { granted, error in
        if let error {
          print("❌ Notification auth error:", error)
        } else {
          print("🔔 Notification auth granted:", granted)
        }
      }
    }
  }
}
