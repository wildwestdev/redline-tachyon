//
//  SpeedTripActivityAttributes.swift
//  Speed Demon
//
//  Created by Craig Little on 4/12/2025.
//

import Foundation
import ActivityKit

struct SpeedTripActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Live-updating values
        var speedKmh: Double
        var distanceKm: Double
        var tripName: String
        var useImperialUnits: Bool
    }

    // Static attributes (don’t change during activity)
    var id: UUID
}
