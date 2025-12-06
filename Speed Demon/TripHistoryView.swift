//
//  TripHostoryView.swift
//  Speed Demon
//
//  Created by Craig Little on 4/12/2025.
//

import SwiftUI

struct TripHistoryView: View {
    @Binding var trip: Trip
    @AppStorage("useImperialUnits") private var useImperialUnits: Bool = false

    private var sortedSessions: [TripSession] {
        trip.sessions.sorted { $0.startDate > $1.startDate }
    }

    var body: some View {
        List {
            if sortedSessions.isEmpty {
                Section {
                    Text("No sessions recorded yet.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(sortedSessions) { session in
                    sessionRow(session)
                }
            }
        }
        .navigationTitle("\(trip.name) History")
    }

    @ViewBuilder
    private func sessionRow(_ session: TripSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Date & time
            HStack {
                Text(session.startDate, style: .date)
                Text(session.startDate, style: .time)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            // Duration
            let durationSeconds = session.duration
            let minutes = Int(durationSeconds) / 60
            let seconds = Int(durationSeconds) % 60

            Text(String(format: "Duration: %d:%02d", minutes, seconds))
                .font(.footnote)
                .foregroundStyle(.secondary)

            // Distance and average speed
            let baseKm = session.distanceKm
            let avgKmh = session.averageSpeedKmh

            let distance = useImperialUnits ? baseKm * 0.621371 : baseKm
            let avgSpeed = useImperialUnits ? avgKmh * 0.621371 : avgKmh

            let distanceUnit = useImperialUnits ? "mi" : "km"
            let speedUnit = useImperialUnits ? "mph" : "km/h"

            Text(String(format: "Distance: %.3f %@", distance, distanceUnit))
                .font(.body.monospacedDigit())

            Text(String(format: "Average speed: %.1f %@", avgSpeed, speedUnit))
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        TripHistoryView(
            trip: .constant(
                Trip(
                    name: "Sample Trip",
                    distanceMeters: 12345,
                    isRunning: false,
                    sessions: [
                        TripSession(
                            startDate: Date().addingTimeInterval(-3600),
                            endDate: Date(),
                            distanceMeters: 8000
                        )
                    ]
                )
            )
        )
    }
}
