//
//  NewsCacheManager.swift
//  air
//
//  Created by Dylan Karunanayake on a day (i forgot)
//

import Foundation

private struct CachedNewsPayload: Codable {
    let articles: [NewsArticle]
    let fetchedAt: Date
}

@MainActor
final class NewsCacheManager {
    static let shared = NewsCacheManager()

    private let filename = "news_cache.json"
    private let cacheDuration: TimeInterval = 4 * 60 * 60 // 4 hours

    private init() {}

    func loadIfFresh() -> [NewsArticle]? {
        guard let payload = JSONManager.load(CachedNewsPayload.self, from: filename, location: .cache) else {
            return nil
        }

        let age = Date().timeIntervalSince(payload.fetchedAt)
        guard age < cacheDuration else { return nil }

        return payload.articles
    }

    func save(_ articles: [NewsArticle]) {
        let payload = CachedNewsPayload(articles: articles, fetchedAt: Date())
        try? JSONManager.save(payload, to: filename, location: .cache)
    }

    func clear() {
        try? JSONManager.delete(filename, location: .cache)
    }
}
