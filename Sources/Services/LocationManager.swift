//==============================================================
//  File: LocationManager.swift
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
//    Defines LocationManager for the Speed Demon project.
//
//  Changes:
//  Author  Date        Change
//  ----------------------------------------------------------------------------------
//==============================================================
//
// SPDX-FileCopyrightText: 2026 Craig Little
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Combine
import CoreLocation
import CoreMotion
import Foundation

final class LocationManager: NSObject, ObservableObject {
  static let shared = LocationManager()
  @Published var speedKmh: Double = 0
  @Published var stepDistance: Double = 0
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
  @Published var lastError: String?
  @Published var headingDegrees: Double = 0
  @Published var altitudeMeters: Double = 0
  @Published var currentRoad: String = ""
  @Published var currentTown: String = ""
  @Published var isLikelyMoving: Bool = false

  var currentPlaceSummary: String {
    if !currentRoad.isEmpty, !currentTown.isEmpty {
      return "\(currentRoad), \(currentTown)"
    }

    if !currentTown.isEmpty {
      return currentTown
    }

    if !currentRoad.isEmpty {
      return currentRoad
    }

    return ""
  }

  private let manager = CLLocationManager()
  private let motionManager = CMMotionManager()
  private let geocoder = CLGeocoder()

  private var lastLocation: CLLocation?
  private var speedCheckTimer: Timer?
  private var lastSignificantMotionTime: Date = .distantPast
  private var isGeocoding = false
  private var lastGeocodeLocation: CLLocation?
  private var lastGeocodeDate: Date?
  private var lastSpeedUpdateTime: Date = .init()

  private let speedZeroTimeout: TimeInterval = 3.0
  private let stationarySpeedThreshold: Double = 0.5
  private let motionUpdateInterval: TimeInterval = 0.1
  private let motionAccelerationThreshold: Double = 0.05
  private let motionStationaryTimeout: TimeInterval = 4.0

  override init() {
    super.init()

    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.activityType = .automotiveNavigation
    manager.distanceFilter = 1
    manager.pausesLocationUpdatesAutomatically = false

    manager.requestWhenInUseAuthorization()
    manager.requestAlwaysAuthorization()

    startMotionUpdates()
  }

  func start() {
    manager.startUpdatingLocation()
    manager.startUpdatingHeading()
    manager.desiredAccuracy = kCLLocationAccuracyBest

    speedCheckTimer?.invalidate()
    speedCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.evaluateStationaryState()
    }
  }

  func stop() {
    manager.stopUpdatingLocation()
    speedCheckTimer?.invalidate()
    speedCheckTimer = nil
  }

  func setBackgroundTracking(enabled: Bool) {
    manager.allowsBackgroundLocationUpdates = enabled
    manager.showsBackgroundLocationIndicator = enabled
  }
}

extension LocationManager: CLLocationManagerDelegate {
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus

    switch authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      lastError = nil
      start()
    case .denied, .restricted:
      lastError = "Location access denied. Enable it in Settings."
      stop()
    default:
      break
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading

    DispatchQueue.main.async {
      self.headingDegrees = heading
    }
  }

  func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let newLocation = locations.last else {
      return
    }

    let rawSpeed = max(newLocation.speed, 0)
    let computedSpeedKmh = rawSpeed * 3.6
    lastSpeedUpdateTime = Date()

    DispatchQueue.main.async {
      self.speedKmh = computedSpeedKmh
      self.altitudeMeters = newLocation.altitude

      if rawSpeed >= self.stationarySpeedThreshold {
        self.lastSpeedUpdateTime = Date()
      }
    }

    var delta: Double = 0
    if let last = lastLocation, newLocation.horizontalAccuracy >= 0 {
      delta = newLocation.distance(from: last)
    }

    lastLocation = newLocation

    DispatchQueue.main.async {
      self.stepDistance = max(delta, 0)
    }

    maybeReverseGeocode(location: newLocation)
  }

  func locationManager(_: CLLocationManager, didFailWithError error: Error) {
    DispatchQueue.main.async {
      self.lastError = error.localizedDescription
    }
  }
}

private extension LocationManager {
  func startMotionUpdates() {
    guard motionManager.isDeviceMotionAvailable else {
      return
    }

    motionManager.deviceMotionUpdateInterval = motionUpdateInterval
    motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
      guard let self, let motion else {
        return
      }

      let acceleration = motion.userAcceleration
      let magnitude = sqrt(
        acceleration.x * acceleration.x +
          acceleration.y * acceleration.y +
          acceleration.z * acceleration.z)

      let now = Date()
      if magnitude > motionAccelerationThreshold {
        lastSignificantMotionTime = now
        isLikelyMoving = true
      } else {
        let timeSinceMotion = now.timeIntervalSince(lastSignificantMotionTime)
        if timeSinceMotion > motionStationaryTimeout {
          isLikelyMoving = false
        }
      }
    }
  }

  func maybeReverseGeocode(location: CLLocation) {
    let now = Date()

    if isGeocoding {
      return
    }

    if let lastLoc = lastGeocodeLocation,
       location.distance(from: lastLoc) < 200,
       let lastDate = lastGeocodeDate,
       now.timeIntervalSince(lastDate) < 30
    {
      return
    }

    isGeocoding = true
    lastGeocodeLocation = location
    lastGeocodeDate = now

    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
      guard let self else {
        return
      }

      DispatchQueue.main.async {
        self.isGeocoding = false

        if let error {
          print("Reverse geocode error:", error)
          return
        }

        guard let placemark = placemarks?.first else {
          return
        }

        let road = placemark.thoroughfare ?? ""
        let town =
          placemark.locality ??
          placemark.subLocality ??
          placemark.administrativeArea ??
          ""

        self.currentRoad = road
        self.currentTown = town
      }
    }
  }

  func evaluateStationaryState() {
    let now = Date()
    let timeSinceSpeedUpdate = now.timeIntervalSince(lastSpeedUpdateTime)
    let timeSinceMotion = now.timeIntervalSince(lastSignificantMotionTime)

    let gpsStale = timeSinceSpeedUpdate > speedZeroTimeout
    let noRecentMotion = timeSinceMotion > motionStationaryTimeout

    DispatchQueue.main.async {
      if gpsStale, noRecentMotion, self.speedKmh != 0 {
        self.speedKmh = 0
      }

      let lowSpeedThresholdKmh = 3.0
      if self.speedKmh > 0,
         self.speedKmh < lowSpeedThresholdKmh,
         noRecentMotion
      {
        self.speedKmh = 0
      }

      if gpsStale, noRecentMotion {
        self.isLikelyMoving = false
      }
    }
  }
}
