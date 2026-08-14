//
//  NewsCacheManager.swift
//  air
//

import Foundation

private struct CachedNewsPayload: Codable {
    let articles: [NewsArticle]
    let fetchedAt: Date
}

@MainActor
final class NewsCacheManager {
    static let shared = NewsCacheManager()

    private let storageKey = "cachedNewsPayload_v2"
    private let cacheDuration: TimeInterval = 4 * 60 * 60 // 4 hours

    private init() {}

    func loadIfFresh() -> [NewsArticle]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let payload = try? JSONDecoder().decode(CachedNewsPayload.self, from: data) else {
            return nil
        }

        let age = Date().timeIntervalSince(payload.fetchedAt)
        guard age < cacheDuration else { return nil }

        return payload.articles
    }

    func save(_ articles: [NewsArticle]) {
        let payload = CachedNewsPayload(articles: articles, fetchedAt: Date())
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
