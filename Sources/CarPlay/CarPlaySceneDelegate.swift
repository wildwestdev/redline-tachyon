//==============================================================
//  File: CarPlaySceneDelegate.swift
//  Project: Speed Demon
//
//  Created by Craig Little on 11/05/2026
//  © 2026 Craig Little. All rights reserved.
//
//  Version: 1.0.2
//  Last Modified: 11/05/2026
//  Maintainer: Craig Little
//
//  Description:
//    Hosts the CarPlay scene lifecycle and mounts Speed Demon templates.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 11/05/2026 Added initial CarPlay scene delegate.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//

import CarPlay
import Combine
import Foundation

/// Connects the app's shared state to a CarPlay template scene.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  // MARK: - Scene State

  private var interfaceController: CPInterfaceController?
  private let locationManager = LocationManager.shared
  private let tripStore = TripStore.shared
  private var templateFactory: CarPlayTemplateFactory?
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - CPTemplateApplicationSceneDelegate

  /// Called when CarPlay scene connects and template UI can be displayed.
  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController,
    to window: CPWindow)
  {
    self.interfaceController = interfaceController
    locationManager.start()

    templateFactory = CarPlayTemplateFactory(
      locationManager: locationManager,
      tripStore: tripStore)

    renderRoot(animated: false)
    bindUpdates()
  }

  /// Called when CarPlay scene disconnects and resources can be released.
  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController,
    from window: CPWindow)
  {
    cancellables.removeAll()
    templateFactory = nil
    self.interfaceController = nil
  }

  // MARK: - Rendering

  /// Rebuilds and sets the CarPlay root template from current app state.
  private func renderRoot(animated: Bool) {
    guard
      let interfaceController,
      let templateFactory
    else {
      return
    }

    let template = templateFactory.makeRootTemplate(interfaceController: interfaceController)
    interfaceController.setRootTemplate(template, animated: animated) { _, _ in }
  }

  /// Subscribes to speed and trip updates and refreshes templates when state changes.
  private func bindUpdates() {
    locationManager.$speedKmh
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.renderRoot(animated: false)
      }
      .store(in: &cancellables)

    tripStore.$trips
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.renderRoot(animated: false)
      }
      .store(in: &cancellables)
  }
}
