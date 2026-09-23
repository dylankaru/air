import SwiftUI

struct NewsCard: View {
    @Environment(\.activeTheme) private var theme
    @AppStorage("news_user_prefs") private var newsPreference: String = "news today"
    
    @State private var isTestingNews = false

    @State private var articles: [NewsArticle] = []
    @State private var preloadedImages: [String: NSImage] = [:]
    @State private var currentIndex = 0
    @State private var cycleTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var isReady = false
    
    @State private var isHovering = false
    @State private var moveDirection: Int = 1

    var body: some View {
        Card {
            Group {
                //                if !turnOffNews {
                ZStack {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(theme.textColour)
                            .font(.caption)
                    } else if !isReady {
                        Text("Loading news…")
                            .foregroundColor(theme.textColour)
                    } else {
                        NewsCardContent(
                            article: articles[currentIndex],
                            image: preloadedImages[articles[currentIndex].id]
                        )
                        .id(articles[currentIndex].id)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: moveDirection >= 0 ? .bottom : .top).combined(with: .opacity),
                                removal: .move(edge: moveDirection >= 0 ? .top : .bottom).combined(with: .opacity)
                            )
                        )
                        .overlay {
                            ScrollDetector { steps in
                                moveArticle(by: steps)
                            }
                        }
                        .overlay(alignment: .trailing) {
                            if isHovering && !articles.isEmpty {
                                VStack(spacing: 8) {
                                    let maxDots = min(articles.count, 10)
                                    ForEach(0..<maxDots, id: \.self) { index in
                                        Circle()
                                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                moveDirection = index >= currentIndex ? 1 : -1
                                                currentIndex = index
                                                startCycling()
                                            }
                                    }
                                }
                                .padding(.trailing, 4)
                                .transition(.opacity)
                            }
                        }
                    }
                }
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovering = hovering
                    }
                }
                .clipped()
                .padding(10)
                //                } else {
                //                    VStack {
                //                        Spacer()
                //                        Text("You've turned off news... I see how it is")
                //                            .foregroundColor(theme.textColour)
                //                            .frame(maxWidth: .infinity, alignment: .center)
                //                        Spacer()
                //                    }
                //                }
            }
            .task {
                await loadNews()
            }
            .onDisappear {
                cycleTask?.cancel()
            }
        }
    }
    
    private func moveArticle(by steps: Int) {
        guard !articles.isEmpty else { return }
        
        let clampedSteps = steps > 0 ? 1 : (steps < 0 ? -1 : 0)
        guard clampedSteps != 0 else { return }
        
        moveDirection = clampedSteps
        
        let newIndex = (currentIndex + clampedSteps) % articles.count
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentIndex = newIndex < 0 ? newIndex + articles.count : newIndex
        }
        
        startCycling()
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
                    guard let urlString = imageURL, let url = URL(string: urlString) else {
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
                              (200...299).contains(httpResponse.statusCode),
                              let image = NSImage(data: data) else {
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
                if let image { result[id] = image }
            }
            return result
        }
    }

    private func startCycling() {
        cycleTask?.cancel()
        cycleTask = Task { @MainActor in
            while !Task.isCancelled {
                let delay = Double.random(in: 4...5)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled, !articles.isEmpty else { continue }
                
                moveDirection = 1
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    currentIndex = (currentIndex + 1) % articles.count
                }
            }
        }
    }
}

private struct NewsCardContent: View {
    @Environment(\.activeTheme) private var theme
    
    let article: NewsArticle
    let image: NSImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.textColour.opacity(0.12))
                    .overlay(
                        Image(systemName: "newspaper")
                            .font(.system(size: 24))
                            .foregroundColor(theme.textColour.opacity(0.35))
                    )
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(article.title)
                    .foregroundColor(.white)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(height: 238)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .compositingGroup()
        .drawingGroup()
    }
}
