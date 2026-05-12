//==============================================================
//  File: CarPlayTemplateFactory.swift
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
//    Builds CarPlay list templates and actions from live Speed Demon data.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//  Craig Little 11/05/2026 Added initial CarPlay list template factory.
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//

import CarPlay
import Foundation
import UIKit

/// Builds CarPlay templates using the current app state.
final class CarPlayTemplateFactory {
  // MARK: - Dependencies

  private let locationManager: LocationManager
  private let tripStore: TripStore

  // MARK: - Initialization

  /// Creates a factory that reads from shared location and trip models.
  init(locationManager: LocationManager, tripStore: TripStore) {
    self.locationManager = locationManager
    self.tripStore = tripStore
  }

  // MARK: - Public API

  /// Creates the root CarPlay template showing live speed and trip controls.
  func makeRootTemplate(interfaceController: CPInterfaceController) -> CPTemplate {
    let statusSection = makeStatusSection()
    let tripSection = makeTripSection(interfaceController: interfaceController)

    let root = CPListTemplate(
      title: "SpeedDemon",
      sections: [statusSection, tripSection])
    root.tabTitle = "Drive"
    root.tabImage = UIImage(systemName: "speedometer")
    return root
  }

  // MARK: - Template Sections

  /// Builds a section describing current telemetry values.
  private func makeStatusSection() -> CPListSection {
    let speedItem = CPListItem(
      text: "Speed",
      detailText: String(format: "%.0f km/h", locationManager.speedKmh))
    speedItem.isEnabled = false

    let headingItem = CPListItem(
      text: "Heading",
      detailText: String(format: "%.0f°", locationManager.headingDegrees))
    headingItem.isEnabled = false

    let altitudeItem = CPListItem(
      text: "Altitude",
      detailText: String(format: "%.0f m", locationManager.altitudeMeters))
    altitudeItem.isEnabled = false

    return CPListSection(items: [speedItem, headingItem, altitudeItem], header: "Live Data", sectionIndexTitle: nil)
  }

  /// Builds a section with current trips and start/stop controls.
  private func makeTripSection(interfaceController: CPInterfaceController) -> CPListSection {
    if tripStore.trips.isEmpty {
      let emptyItem = CPListItem(text: "No Trips", detailText: "Create a trip on iPhone to control it from CarPlay.")
      emptyItem.isEnabled = false
      return CPListSection(items: [emptyItem], header: "Trips", sectionIndexTitle: nil)
    }

    let items = tripStore.trips.map { trip in
      makeTripItem(trip: trip, interfaceController: interfaceController)
    }
    return CPListSection(items: items, header: "Trips", sectionIndexTitle: nil)
  }

  /// Builds one list item for a trip with toggle behavior.
  private func makeTripItem(trip: Trip, interfaceController: CPInterfaceController) -> CPListItem {
    let detail = String(format: "%.2f km • %@", trip.distanceKm, trip.isRunning ? "Running" : "Paused")
    let item = CPListItem(text: trip.name, detailText: detail)

    item.handler = { [weak self] _, completion in
      guard let self else {
        completion()
        return
      }

      self.toggleTrip(tripID: trip.id)
      let refreshed = self.makeRootTemplate(interfaceController: interfaceController)
      interfaceController.setRootTemplate(refreshed, animated: true) { _, _ in }
      completion()
    }

    return item
  }

  // MARK: - Actions

  /// Toggles running state for a trip and opens/closes sessions accordingly.
  private func toggleTrip(tripID: UUID) {
    tripStore.toggleTripRunningState(tripID: tripID)
  }
}
