//
//  WorldClockSettingsPanel.swift
//  air
//
//  Created by Dylan Karunanayake on 9/9/2026.
//

import SwiftUI

let worldClockConfigFilename = "world_clock_config.json"
let worldClockConfigDidChangeNotification = Notification.Name("worldClockConfigDidChange")

struct WorldClockConfig: Codable {
    var cities: [String] = ["Europe/London", "America/New_York", "Asia/Tokyo", "Australia/Perth"]
}

struct ConfiguredCity: Identifiable, Equatable {
    let id = UUID()
    var timeZoneIdentifier: String

    var displayName: String {
        timeZoneIdentifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? timeZoneIdentifier
    }

    var regionName: String {
        let parts = timeZoneIdentifier.split(separator: "/")
        return parts.count > 1 ? String(parts[0]).replacingOccurrences(of: "_", with: " ") : ""
    }

    var timeZone: TimeZone? {
        TimeZone(identifier: timeZoneIdentifier)
    }

    var formattedOffset: String {
        guard let tz = timeZone else { return "" }
        let seconds = tz.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        return minutes == 0 ? String(format: "UTC%+d", hours) : String(format: "UTC%+d:%02d", hours, minutes)
    }

    var currentTimeString: String {
        guard let tz = timeZone else { return "" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

struct AvailableCity: Identifiable, Hashable {
    let id: String
    let timeZoneIdentifier: String

    var displayName: String {
        timeZoneIdentifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? timeZoneIdentifier
    }

    var regionName: String {
        let parts = timeZoneIdentifier.split(separator: "/")
        return parts.count > 1 ? String(parts[0]).replacingOccurrences(of: "_", with: " ") : ""
    }
}

struct WorldClockSettingsPanel: View {
    @State private var cities: [ConfiguredCity] = []
    @State private var searchText: String = ""
    @State private var isHovered = false

    private var availableCities: [AvailableCity] {
        TimeZone.knownTimeZoneIdentifiers
            .sorted()
            .map { AvailableCity(id: $0, timeZoneIdentifier: $0) }
    }

    private var filteredCities: [AvailableCity] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let existingIDs = Set(cities.map { $0.timeZoneIdentifier })
        return availableCities.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) &&
            !existingIDs.contains($0.id)
        }
    }

    var body: some View {
        SettingsPanel(name: "World Clock") {
            Section {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add City")
                                .font(.headline)

                            TextField("Search city or time zone:", text: $searchText)
                                .textFieldStyle(.roundedBorder)

                            if !searchText.isEmpty && !filteredCities.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(filteredCities.prefix(8)) { city in
                                        Button {
                                            addCity(city.id)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(city.displayName)
                                                        .font(.body)
                                                        .foregroundColor(.primary)
                                                    if !city.regionName.isEmpty {
                                                        Text(city.regionName)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                Spacer()
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.secondary)
//                                                    .onHover { hovering in
//                                                        isHovered = hovering
//                                                    }
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Divider()
                                    }
                                }
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.top, 4)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Active Locations (\(cities.count))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            List {
                                ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                                    CityRowView(
                                        city: city,
                                        canDelete: cities.count > 1,
                                        onDelete: { deleteCity(at: index) }
                                    )
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                    .listRowBackground(Color.clear)
                                }
                                .onMove(perform: moveCities)
                            }
                            .listStyle(.plain)
                            .scrollDisabled(true)
                            .scrollContentBackground(.hidden)
                            .frame(height: max(CGFloat(cities.count) * 50, 50))
                        }
                    }
                    .padding()
                }
                .onAppear(perform: loadCities)
                .onChange(of: cities) { _, newCities in
                    saveCities(newCities)
                }
            } header: {
                Text("World Clock Layout")
            } footer: {
                Text("Drag rows to reorder cities. At least one city is required.")
            }
        }
    }

    private func addCity(_ identifier: String) {
        guard !cities.contains(where: { $0.timeZoneIdentifier == identifier }) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            cities.append(ConfiguredCity(timeZoneIdentifier: identifier))
        }
        searchText = ""
    }

    private func deleteCity(at index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = cities.remove(at: index)
        }
    }

    private func moveCities(from source: IndexSet, to destination: Int) {
        cities.move(fromOffsets: source, toOffset: destination)
    }

    private func loadCities() {
        let config = JSONManager.load(WorldClockConfig.self, from: worldClockConfigFilename) ?? WorldClockConfig()
        cities = config.cities.map { ConfiguredCity(timeZoneIdentifier: $0) }
    }

    private func saveCities(_ newCities: [ConfiguredCity]) {
        let config = WorldClockConfig(cities: newCities.map { $0.timeZoneIdentifier })
        do {
            try JSONManager.save(config, to: worldClockConfigFilename)
            NotificationCenter.default.post(name: worldClockConfigDidChangeNotification, object: nil)
        } catch {
            print("Failed to save world clock config: \(error)")
        }
    }
}

struct CityRowView: View {
    let city: ConfiguredCity
    let canDelete: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text(city.displayName)
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            Text("\(city.regionName) • \(city.formattedOffset)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}
