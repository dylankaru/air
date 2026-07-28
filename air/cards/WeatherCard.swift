//
//  WeatherCard.swift
//  air
//
//  Created by Dylan Karunanayake on 28/7/2026.
//

import SwiftUI
import CoreLocation

@MainActor
final class WeatherLocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate else { return }
        Task { @MainActor in
            self.continuation?.resume(returning: coordinate)
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
        }
    }
}

struct WeatherCard: View {

    @State private var weather: WeatherResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var locationProvider = WeatherLocationProvider()

    var body: some View {
        Card() {
            HStack(alignment: .top, spacing: 20) {
                if let weather {
                    todaySection(weather.today)

                    Divider()

                    detailsSection(weather.today)
                        .layoutPriority(1)

                    Divider()

                    upcomingSection(weather.upcoming)
                } else if isLoading {
                    ProgressView()
                } else {
                    errorView
                }
            }
            .padding(16)
        }
        .task {
            await loadWeather()
        }
    }

    private func todaySection(_ today: TodayForecast) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(today.condition)
                .font(.subheadline)
                .foregroundStyle(Color.middark)

            Text("\(Int(today.currentTempC.rounded()))°")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(Color.middark)
                .fixedSize()

            HStack(spacing: 14) {
                Label("\(Int(today.maxTempC.rounded()))°/\(Int(today.minTempC.rounded()))°",
                      systemImage: "thermometer.medium")
                Label("\(today.chanceOfRain)%", systemImage: "drop.fill")
            }
            .font(.footnote)
            .foregroundStyle(Color.middark)
            .fixedSize()
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func detailsSection(_ today: TodayForecast) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            detailItem(icon: "wind", title: "Wind", value: "\(Int(today.windKph.rounded())) km/h \(today.windDir)")
            detailItem(icon: "humidity", title: "Humidity", value: "\(today.humidity)%")
            detailItem(icon: "sun.max.fill", title: "UV Index", value: String(format: "%.1f", today.uv))
//            detailItem(icon: "sunrise.fill", title: "Sun", value: "\(today.sunrise), \(today.sunset)")
        }
        .frame(minWidth: 140, alignment: .leading)
    }

    private func detailItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.middark)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.middark)
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.middark)
            }
        }
    }

    private func upcomingSection(_ days: [DayForecast]) -> some View {
        HStack(spacing: 24) {
            ForEach(days, id: \.date) { day in
                VStack(spacing: 8) {
                    Text(shortWeekday(from: day.date))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.middark)

                    Image(systemName: symbol(for: day.condition))
                        .font(.callout)
                        .foregroundStyle(Color.middark)
                        .frame(height: 18)

                    Text("\(Int(day.maxTempC.rounded()))°/\(Int(day.minTempC.rounded()))°")
                        .font(.caption2)
                        .foregroundStyle(Color.middark)

                    Text("\(day.chanceOfRain)%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .frame(minWidth: 44)
                .padding(.top, 24)
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
            Text(errorMessage ?? "Couldn't load weather")
                .font(.caption)
                .foregroundStyle(Color.middark)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
    }

    private func loadWeather() async {
        isLoading = true
        errorMessage = nil
        do {
            let coordinate = try await locationProvider.requestLocation()
            weather = try await fetchWeather(lat: coordinate.latitude, lon: coordinate.longitude)
        } catch {
            errorMessage = error.localizedDescription
            print(errorMessage ?? "Unknown error")
        }
        isLoading = false
    }

    private func shortWeekday(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let weekday = DateFormatter()
        weekday.dateFormat = "EEE"
        return weekday.string(from: date)
    }

    private func symbol(for condition: String) -> String {
        let lowered = condition.lowercased()
        if lowered.contains("rain") { return "cloud.rain.fill" }
        if lowered.contains("cloud") { return "cloud.fill" }
        if lowered.contains("sun") || lowered.contains("clear") { return "sun.max.fill" }
        if lowered.contains("storm") || lowered.contains("thunder") { return "cloud.bolt.fill" }
        if lowered.contains("snow") { return "cloud.snow.fill" }
        return "cloud.sun.fill"
    }
}
