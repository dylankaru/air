//
//  APIRequest.swift
//  air
//
//  Created by Dylan Karunanayake on 27/7/2026.
//

import Foundation

struct GreetingRequest: Encodable {
    let userName: String
    let timeOfDay: String

    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case timeOfDay = "time_of_day"
    }
}

struct GreetingResponse: Decodable {
    let greeting: String
}

func fetchGreeting(userName: String, timeOfDay: String) async throws -> GreetingResponse {
    guard let url = URL(string: "https://air-api.destinyorg.com.au/greeting") else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = GreetingRequest(userName: userName, timeOfDay: timeOfDay)
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(GreetingResponse.self, from: data)
}
