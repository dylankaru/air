import Foundation

struct DayForecast: Decodable {
    let date: String
    let condition: String
    let maxTempC: Double
    let minTempC: Double
    let avgTempC: Double
    let chanceOfRain: Int

    enum CodingKeys: String, CodingKey {
        case date, condition
        case maxTempC = "max_temp_c"
        case minTempC = "min_temp_c"
        case avgTempC = "avg_temp_c"
        case chanceOfRain = "chance_of_rain"
    }
}

struct TodayForecast: Decodable {
    let currentTempC: Double
    let currentCondition: String
    let humidity: Int
    let windKph: Double
    let windDir: String
    let uv: Double
    let sunrise: String?
    let sunset: String?
    let date: String
    let condition: String
    let maxTempC: Double
    let minTempC: Double
    let avgTempC: Double
    let chanceOfRain: Int

    let windGustKph: Double?
    let feelslikeC: Double?
    let pressureMb: Double?
    let precipMm: Double?
    let cloud: Int?
    let visKm: Double?
    let dewPointC: Double?
    let heatIndexC: Double?
    let windChillC: Double?
    let fireDanger: String?
    let moldRisk: String?
    let aqiUsEpaIndex: Int?
    let aqiCategory: String?
    let aqiPm2_5: Double?
    let moonrise: String?
    let moonset: String?
    let moonPhase: String?
    let moonIllumination: Int?
    let solarNoon: String?
    let daylightMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case currentTempC = "current_temp_c"
        case currentCondition = "current_condition"
        case humidity
        case windKph = "wind_kph"
        case windDir = "wind_dir"
        case uv, sunrise, sunset, date, condition
        case maxTempC = "max_temp_c"
        case minTempC = "min_temp_c"
        case avgTempC = "avg_temp_c"
        case chanceOfRain = "chance_of_rain"

        case windGustKph = "wind_gust_kph"
        case feelslikeC = "feelslike_c"
        case pressureMb = "pressure_mb"
        case precipMm = "precip_mm"
        case cloud
        case visKm = "vis_km"
        case dewPointC = "dew_point_c"
        case heatIndexC = "heat_index_c"
        case windChillC = "wind_chill_c"
        case fireDanger = "fire_danger"
        case moldRisk = "mold_risk"
        case aqiUsEpaIndex = "aqi_us_epa_index"
        case aqiCategory = "aqi_category"
        case aqiPm2_5 = "aqi_pm2_5"
        case moonrise, moonset
        case moonPhase = "moon_phase"
        case moonIllumination = "moon_illumination"
        case solarNoon = "solar_noon"
        case daylightMinutes = "daylight_minutes"
    }
}

struct HourlyForecast: Decodable {
    let time: String
    let tempC: Double
    let condition: String
    let chanceOfRain: Int
    let windKph: Double

    enum CodingKeys: String, CodingKey {
        case time
        case tempC = "temp_c"
        case condition
        case chanceOfRain = "chance_of_rain"
        case windKph = "wind_kph"
    }
}

struct WeatherAlert: Decodable {
    let headline: String
    let severity: String
    let event: String
}

struct WeatherResponse: Decodable {
    let today: TodayForecast
    let upcoming: [DayForecast]
    let hourly: [HourlyForecast]
    let alerts: [WeatherAlert]
}

enum WeatherMetric: String, CaseIterable, Identifiable, Codable {
    case feelsLike = "Feels Like"
    case conditionText = "Condition Text"
    case windSpeed = "Wind Speed & Direction"
    case windGust = "Wind Gust"
    case pressure = "Barometric Pressure"
    case humidity = "Humidity"
    case cloudCover = "Cloud Cover"
    case dewPoint = "Dew Point"
    case precipAmount = "Precipitation Amount"
    case visibility = "Visibility"
    case uvIndex = "UV Index"

    case tempBounds = "Daily High / Low"
    case precipChance = "Chance of Rain / Snow"

    case sunTimes = "Sunrise & Sunset"
    case moonPhase = "Moon Phase & Illumination"
    case moonriseMoonset = "Moonrise & Moonset"
    case daylightDuration = "Daylight Hours"
    case solarNoon = "Solar Noon"

    case hourlyForecast = "Hourly Forecast"
    case futureForecast = "Future Day Forecast"
    case radarMap = "Mini Radar Map"

    case airQuality = "Air Quality Index (AQI)"
    case pollenIndex = "Pollen & Mold Count"
    case moldRisk = "Mold Risk Index"
    case uvCategory = "UV Exposure Level"

    case weatherAlerts = "Severe Weather Alerts"
    case windChill = "Wind Chill Index"
    case heatIndex = "Heat Index"
    case freezeRisk = "Frost & Freeze Warning"
    case fireDanger = "Fire Danger Rating"

    var id: String { rawValue }

    var slotCost: Int {
        switch self {
        case .futureForecast, .hourlyForecast, .radarMap, .weatherAlerts:
            return 3
        default:
            return 1
        }
    }

    var isDataAvailable: Bool {
        switch self {
        case .pollenIndex, .radarMap:
            return false
        default:
            return true
        }
    }
}

func fetchWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
    var components = URLComponents(string: "https://airapi.destinyorg.com.au/weather")
    components?.queryItems = [
        URLQueryItem(name: "lat", value: String(lat)),
        URLQueryItem(name: "lon", value: String(lon)),
    ]

    guard let url = components?.url else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(WeatherResponse.self, from: data)
}
