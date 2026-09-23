//
//  WorldClockCard.swift
//  air
//
//  Created by Dylan Karunanayake on 8/9/2026.
//

import SwiftUI

struct CityClock: Identifiable {
    let id = UUID()
    let name: String
    let timeZoneIdentifier: String
    
    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}

extension CityClock {
    init(timeZoneIdentifier: String) {
        self.init(
            name: timeZoneIdentifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? timeZoneIdentifier,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }
}

struct WorldClockCard: View {
    @Environment(\.activeTheme) private var theme
    
    @State private var hoveredCityID: CityClock.ID?
    @State private var cities: [CityClock] = []
    
    var body: some View {
        Card {
            clockList
        }
        .onAppear {
            loadConfig()
        }
        .onReceive(NotificationCenter.default.publisher(for: worldClockConfigDidChangeNotification)) { _ in
            loadConfig()
        }
    }
    
    private func loadConfig() {
        let config = JSONManager.load(WorldClockConfig.self, from: worldClockConfigFilename) ?? WorldClockConfig()
        cities = config.cities.map { CityClock(timeZoneIdentifier: $0) }
    }
    
    @ViewBuilder
    private var clockList: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            VStack(spacing: 0) {
                ForEach(cities) { city in
                    cityRow(city, date: context.date, isHovered: hoveredCityID == city.id)
                    
                    if city.id != cities.last?.id {
                        Divider().opacity(0)
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func cityRow(_ city: CityClock, date: Date, isHovered: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(city.name)
                    .font(.custom("ClashDisplayVariable-Bold", size: 16))
                    .foregroundColor(theme.textColour)
                
                Text(timeOffsetString(for: city.timeZone, at: date))
                    .font(.caption)
                    .foregroundColor(theme.textColour.opacity(0.8))
            }
            
            Spacer()
            
            Text(isHovered ? date.formattedHoverTime(for: city.timeZone) : date.formattedTime(for: city.timeZone))
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundColor(theme.textColour.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onHover { hovering in
            hoveredCityID = hovering ? city.id : nil
        }
    }
    
    private func timeOffsetString(for targetZone: TimeZone, at date: Date) -> String {
        let currentOffset = TimeZone.current.secondsFromGMT(for: date)
        let targetOffset = targetZone.secondsFromGMT(for: date)
        let hourDifference = (targetOffset - currentOffset) / 3600
        
        if hourDifference == 0 {
            return "Same time"
        } else if hourDifference > 0 {
            return "+\(hourDifference) hrs"
        } else {
            return "\(hourDifference) hrs"
        }
    }
}

extension Date {
    func formattedTime(for timeZone: TimeZone) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = timeZone
        return self.formatted(style)
    }
    
    func formattedHoverTime(for timeZone: TimeZone) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute().second()
        style.timeZone = timeZone
        return self.formatted(style)
    }
}
