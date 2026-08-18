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
    
    @AppStorage("weather_selected_metrics") private var selectedMetrics: [WeatherMetric] = [
        .windSpeed,
        .humidity,
        .uvIndex,
        .futureForecast
    ]
    
    private let columnSlotCapacity = 3
    
    var body: some View {
        let (middleMetrics, rightMetrics) = distribute(selectedMetrics)
        
        Card {
            HStack(alignment: .top, spacing: 0) {
                if let weather {
                    todaySection(weather.today)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Spacer(minLength: 8)
                    
                    if !middleMetrics.isEmpty {
                        columnView(metrics: middleMetrics, weather: weather)
                            .fixedSize(horizontal: true, vertical: false)
                        
                        Spacer(minLength: 8)
                    }
                    
                    if !rightMetrics.isEmpty {
                        columnView(metrics: rightMetrics, weather: weather)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    errorView
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(10)
        }
        .task {
            await loadWeather()
        }
    }

    private func todaySection(_ today: TodayForecast) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(today.condition)
                .font(.system(size: 10))
                .foregroundStyle(Color.middark)
                .lineLimit(1)

            Text("\(Int(today.currentTempC.rounded()))°")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color.middark)

            HStack(spacing: 8) {
                Label("\(Int(today.maxTempC.rounded()))°/\(Int(today.minTempC.rounded()))°",
                      systemImage: "thermometer.medium")
                Label("\(today.chanceOfRain)%", systemImage: "drop.fill")
            }
            .font(.system(size: 9))
            .foregroundStyle(Color.middark)
            .lineLimit(1)
        }
        .padding(.top, 2)
    }

    private func distribute(_ metrics: [WeatherMetric]) -> (middle: [WeatherMetric], right: [WeatherMetric]) {
        var middle: [WeatherMetric] = []
        var right: [WeatherMetric] = []
        var middleSlots = 0
        var rightSlots = 0

        for metric in metrics {
            if middleSlots + metric.slotCost <= columnSlotCapacity {
                middle.append(metric)
                middleSlots += metric.slotCost
            } else if rightSlots + metric.slotCost <= columnSlotCapacity {
                right.append(metric)
                rightSlots += metric.slotCost
            }
        }

        return (middle, right)
    }

    private func columnView(metrics: [WeatherMetric], weather: WeatherResponse) -> some View {
        let smallMetrics = metrics.filter { $0.slotCost == 1 }
        let bigMetrics = metrics.filter { $0.slotCost > 1 }

        return VStack(alignment: .leading, spacing: 12) {
            ForEach(smallMetrics) { metric in
                detailRow(for: metric, today: weather.today)
            }
            ForEach(bigMetrics) { metric in
                bigWidget(for: metric, weather: weather)
            }
        }
        .padding(.top, 3)
    }

    private func detailRow(for metric: WeatherMetric, today: TodayForecast) -> some View {
        let (icon, title, value) = content(for: metric, today: today)
        return detailItem(icon: icon, title: title, value: value)
    }

    private func detailItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Color.middark)
                .frame(width: 12)

            HStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.middark.opacity(0.7))
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.middark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    private func content(for metric: WeatherMetric, today: TodayForecast) -> (icon: String, title: String, value: String) {
        switch metric {
        case .feelsLike:
            return ("thermometer.variable", "Feels Like", fmt(today.feelslikeC, suffix: "°"))
        case .conditionText:
            return ("cloud.fill", "Condition", today.condition)
        case .windSpeed:
            return ("wind", "Wind", "\(Int(today.windKph.rounded())) km/h \(today.windDir)")
        case .windGust:
            return ("wind", "Gust", fmt(today.windGustKph, suffix: " km/h"))
        case .pressure:
            return ("gauge", "Pressure", fmt(today.pressureMb, suffix: " mb"))
        case .humidity:
            return ("humidity", "Humidity", "\(today.humidity)%")
        case .cloudCover:
            return ("cloud.fill", "Cloud", fmtInt(today.cloud, suffix: "%"))
        case .dewPoint:
            return ("thermometer.snowflake", "Dew Point", fmt(today.dewPointC, suffix: "°"))
        case .precipAmount:
            return ("drop.fill", "Precip", fmt(today.precipMm, decimals: 1, suffix: " mm"))
        case .visibility:
            return ("eye", "Visibility", fmt(today.visKm, suffix: " km"))
        case .uvIndex:
            return ("sun.max.fill", "UV Index", String(format: "%.1f", today.uv))
        case .tempBounds:
            return ("thermometer.medium", "High/Low", "\(Int(today.maxTempC.rounded()))°/\(Int(today.minTempC.rounded()))°")
        case .precipChance:
            return ("drop.fill", "Rain", "\(today.chanceOfRain)%")
        case .sunTimes:
            return ("sunrise.fill", "Sun", "\(fmtStr(today.sunrise)) / \(fmtStr(today.sunset))")
        case .moonPhase:
            let illumination = today.moonIllumination.map { "\($0)%" } ?? "—"
            return ("moon.fill", "Moon", "\(fmtStr(today.moonPhase)) (\(illumination))")
        case .moonriseMoonset:
            return ("moon.stars.fill", "Moon Times", "\(fmtStr(today.moonrise)) / \(fmtStr(today.moonset))")
        case .daylightDuration:
            return ("hourglass", "Daylight", daylightLabel(today.daylightMinutes))
        case .solarNoon:
            return ("sun.min.fill", "Solar Noon", fmtStr(today.solarNoon))
        case .airQuality:
            return ("aqi.medium", "AQI", fmtStr(today.aqiCategory))
        case .pollenIndex:
            // No pollen data source exists from the current backend/API.
            return ("leaf.fill", "Pollen", "—")
        case .moldRisk:
            return ("umbrella.fill", "Mold Risk", fmtStr(today.moldRisk))
        case .uvCategory:
            return ("sun.max.fill", "UV Level", uvCategoryLabel(today.uv))
        case .windChill:
            return ("wind", "Wind Chill", fmt(today.windChillC, suffix: "°"))
        case .heatIndex:
            return ("thermometer.sun.fill", "Heat Index", fmt(today.heatIndexC, suffix: "°"))
        case .freezeRisk:
            return ("snowflake", "Freeze Risk", today.minTempC <= 0 ? "Yes" : "No")
        case .fireDanger:
            return ("flame.fill", "Fire Danger", fmtStr(today.fireDanger))
        case .hourlyForecast, .futureForecast, .radarMap, .weatherAlerts:
            return ("questionmark", metric.rawValue, "—")
        }
    }

    private func uvCategoryLabel(_ uv: Double) -> String {
        switch uv {
        case ..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
        }
    }

    private func daylightLabel(_ minutes: Int?) -> String {
        guard let minutes else { return "—" }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }

    private func fmt(_ value: Double?, decimals: Int = 0, suffix: String = "") -> String {
        guard let value else { return "—" }
        if decimals == 0 {
            return "\(Int(value.rounded()))\(suffix)"
        }
        return String(format: "%.\(decimals)f", value) + suffix
    }

    private func fmtInt(_ value: Int?, suffix: String = "") -> String {
        guard let value else { return "—" }
        return "\(value)\(suffix)"
    }

    private func fmtStr(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "—" }
        return value
    }

    @ViewBuilder
    private func bigWidget(for metric: WeatherMetric, weather: WeatherResponse) -> some View {
        switch metric {
        case .futureForecast:
            upcomingSection(weather.upcoming)
        case .hourlyForecast:
            if weather.hourly.isEmpty {
                placeholderBig(icon: "clock", text: "Hourly data unavailable")
            } else {
                hourlySection(weather.hourly)
            }
        case .radarMap:
            // No radar tile/imagery provider is wired up yet.
            placeholderBig(icon: "map", text: "Radar unavailable")
        case .weatherAlerts:
            alertsSection(weather.alerts)
        default:
            EmptyView()
        }
    }

    private func placeholderBig(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.middark.opacity(0.6))
            Text(text)
                .font(.system(size: 9))
                .foregroundStyle(Color.middark.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(minWidth: 90)
    }

    private func upcomingSection(_ days: [DayForecast]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(days, id: \.date) { day in
                    VStack(spacing: 8) {
                        Text(shortWeekday(from: day.date))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.middark)

                        Image(systemName: symbol(for: day.condition))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.middark)
                            .frame(height: 11)

                        Text("\(Int(day.maxTempC.rounded()))°/\(Int(day.minTempC.rounded()))°")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.middark)

                        Text("\(day.chanceOfRain)%")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }

    private func hourlySection(_ hours: [HourlyForecast]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(hours.prefix(6), id: \.time) { hour in
                    VStack(spacing: 6) {
                        Text(hour.time)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.middark)

                        Image(systemName: symbol(for: hour.condition))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.middark)
                            .frame(height: 11)

                        Text("\(Int(hour.tempC.rounded()))°")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.middark)

                        Text("\(hour.chanceOfRain)%")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func alertsSection(_ alerts: [WeatherAlert]) -> some View {
        if alerts.isEmpty {
            placeholderBig(icon: "checkmark.circle", text: "No active alerts")
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(alerts.prefix(2), id: \.headline) { alert in
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text(alert.headline)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.middark)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: 150, alignment: .leading)
            .clipped()
        }
    }

    private var errorView: some View {
        VStack(alignment: .center) {
            Text("Couldn't load weather")
                .font(.caption)
                .foregroundStyle(Color.middark)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.middark)
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
