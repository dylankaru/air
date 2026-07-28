//
//  APIWeatherRequest.swift
//  air
//
//  Created by Dylan Karunanayake on 28/7/2026.
//

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
    let sunrise: String
    let sunset: String
    let date: String
    let condition: String
    let maxTempC: Double
    let minTempC: Double
    let avgTempC: Double
    let chanceOfRain: Int

    enum CodingKeys: String, CodingKey {
        case currentTempC = "current_temp_c"
        case currentCondition = "current_condition"
        case humidity
        case windKph = "wind_kph"
        case windDir = "wind_dir"
        case uv
        case sunrise
        case sunset
        case date, condition
        case maxTempC = "max_temp_c"
        case minTempC = "min_temp_c"
        case avgTempC = "avg_temp_c"
        case chanceOfRain = "chance_of_rain"
    }
}

struct WeatherResponse: Decodable {
    let today: TodayForecast
    let upcoming: [DayForecast]
}

func fetchWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
    var components = URLComponents(string: "https://air-api.destinyorg.com.au/weather")
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
