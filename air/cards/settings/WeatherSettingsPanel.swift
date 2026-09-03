//
//  WeatherSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI

struct WeatherSettingsView: View {
    @AppStorage("weather_selected_metrics") private var selectedMetrics: [WeatherMetric] = [
        .windSpeed,
        .humidity,
        .uvIndex,
        .futureForecast
    ]

    private let maxSlots = 6

    private var currentUsedSlots: Int {
        selectedMetrics.reduce(0) { $0 + $1.slotCost }
    }

    var body: some View {
        SettingsPanel(name: "Weather") {
            Section {
                Text("\(currentUsedSlots) of \(maxSlots) display slots used")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } header: {
                Text("Selection Limit")
            } footer: {
                Text("You can select up to 6 metric slots. Standard metrics use 1 slot, while the Future Day Forecast uses 3 slots.")
            }

            Section("Weather Details") {
                ForEach(WeatherMetric.allCases) { metric in
                    Toggle(metric.rawValue, isOn: binding(for: metric))
                        .disabled(!selectedMetrics.contains(metric) && (currentUsedSlots + metric.slotCost > maxSlots))
                }
            }
        }
    }

    private func binding(for metric: WeatherMetric) -> Binding<Bool> {
        Binding(
            get: {
                selectedMetrics.contains(metric)
            },
            set: { isSelected in
                if isSelected {
                    if currentUsedSlots + metric.slotCost <= maxSlots {
                        selectedMetrics.append(metric)
                    }
                } else {
                    selectedMetrics.removeAll { $0 == metric }
                }
            }
        )
    }
}
