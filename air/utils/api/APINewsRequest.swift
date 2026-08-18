//
//  APINewsRequest.swift
//  air
//
//  Created by Dylan Karunanayake on 10/8/2026.
//

import Foundation

struct NewsArticle: Codable, Identifiable {
    var id: String { url }
    let title: String
    let url: String
    let domain: String?
    let language: String?
    let sourceCountry: String?
    let seenDate: String?
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case title
        case url
        case domain
        case language
        case sourceCountry = "source_country"
        case seenDate = "seen_date"
        case imageURL = "image_url"
    }
}

struct NewsResponse: Decodable {
    let query: String
    let count: Int
    let articles: [NewsArticle]
}

func fetchNews(
    query: String = "news today",
    country: String? = nil,
    limit: Int = 10,
    timespan: String = "24h"
) async throws -> NewsResponse {
    var components = URLComponents(string: "https://airapi.destinyorg.com.au/news")
    
    var queryItems = [
        URLQueryItem(name: "query", value: query),
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "timespan", value: timespan)
    ]
    
    if let country = country, !country.trimmingCharacters(in: .whitespaces).isEmpty {
        queryItems.append(URLQueryItem(name: "country", value: country))
    }
    
    components?.queryItems = queryItems

    guard let url = components?.url else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(NewsResponse.self, from: data)
}
