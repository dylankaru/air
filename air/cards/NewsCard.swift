import SwiftUI
import AppKit

struct NewsCard: View {
    @AppStorage("news_user_prefs") private var newsPreference: String = "news today"
    @AppStorage("news_too_distracting") private var turnOffNews: Bool = false
    
    @State private var isTestingNews = false

    @State private var articles: [NewsArticle] = []
    @State private var preloadedImages: [String: NSImage] = [:]
    @State private var currentIndex = 0
    @State private var cycleTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var isReady = false

    var body: some View {
            Card {
                Group {
                    if !turnOffNews {
                        ZStack {
                            if let errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.middark)
                                    .font(.caption)
                            } else if !isReady {
                                Text("Loading news…")
                                    .foregroundColor(.middark)
                            } else {
                                NewsCardContent(
                                    article: articles[currentIndex],
                                    image: preloadedImages[articles[currentIndex].id]
                                )
                                .id(articles[currentIndex].id)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .bottom).combined(with: .opacity)
                                    )
                                )
                            }
                        }
                        .animation(.easeInOut(duration: 0.5), value: currentIndex)
                        .clipped()
                        .padding(10)
                    } else {
                        VStack {
                            Spacer()
                            Text("You've turned off news... I see how it is")
                                .foregroundColor(.middark)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                    }
                }
                .task {
                    await loadNews()
                }
                .onDisappear {
                    cycleTask?.cancel()
                }
            }
        }

    private func loadNews() async {
        do {
            var fetchedArticles: [NewsArticle]

            if !isTestingNews, let cached = NewsCacheManager.shared.loadIfFresh() {
                fetchedArticles = cached
            } else {
                let response = try await fetchNews(query: newsPreference)
                fetchedArticles = response.articles
                NewsCacheManager.shared.save(fetchedArticles)
            }

            fetchedArticles = dedupedByImage(fetchedArticles)

            let images = await preloadImages(for: fetchedArticles)

            articles = fetchedArticles
            preloadedImages = images
            currentIndex = 0
            errorMessage = nil
            isReady = true
            startCycling()
        } catch {
            errorMessage = "Couldn't load news"
        }
    }

    private func dedupedByImage(_ articles: [NewsArticle]) -> [NewsArticle] {
        var seenImageURLs = Set<String>()
        var result: [NewsArticle] = []
        for article in articles {
            if let img = article.imageURL, !img.isEmpty {
                if seenImageURLs.contains(img) { continue }
                seenImageURLs.insert(img)
            }
            result.append(article)
        }
        return result
    }

    private func preloadImages(for articles: [NewsArticle]) async -> [String: NSImage] {
        await withTaskGroup(of: (String, NSImage?).self) { group in
            for article in articles {
                let articleID = article.id
                let imageURL = article.imageURL

                group.addTask {
                    guard let urlString = imageURL,
                          let url = URL(string: urlString) else {
                        return (articleID, nil)
                    }

                    do {
                        let (data, response) = try await withThrowingTaskGroup(of: (Data, URLResponse).self) { g -> (Data, URLResponse) in
                            g.addTask { try await URLSession.shared.data(from: url) }
                            g.addTask {
                                try await Task.sleep(nanoseconds: 4_000_000_000)
                                throw URLError(.timedOut)
                            }
                            let result = try await g.next()!
                            g.cancelAll()
                            return result
                        }

                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else {
                            return (articleID, nil)
                        }

                        guard let image = NSImage(data: data) else {
                            return (articleID, nil)
                        }

                        return (articleID, image)
                    } catch {
                        return (articleID, nil)
                    }
                }
            }

            var result: [String: NSImage] = [:]
            for await (id, image) in group {
                if let image {
                    result[id] = image
                }
            }
            return result
        }
    }

    private func startCycling() {
        cycleTask?.cancel()
        cycleTask = Task {
            while !Task.isCancelled {
                let delay = Double.random(in: 4...5)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled, !articles.isEmpty else { continue }
                
                currentIndex = (currentIndex + 1) % articles.count
            }
        }
    }
}

private struct NewsCardContent: View {
    let article: NewsArticle
    let image: NSImage?

    private let cardHeight: CGFloat = 210
    private let imageHeight: CGFloat = 180

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.middark.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .overlay(
                        Image(systemName: "newspaper")
                            .font(.system(size: 24))
                            .foregroundColor(.middark.opacity(0.35))
                    )
            }

            Text(article.title)
                .foregroundColor(.middark)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: cardHeight, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.widget.opacity(0.6))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
