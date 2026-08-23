//
//  BookmarksCard.swift
//  air
//
//  Created by Dylan Karunanayake on 23/8/2026.
//

import SwiftUI

struct BookmarkItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var systemImage: String
    var openAction: BookmarkOpenAction
}

enum BookmarkOpenAction: Codable, Equatable {
    case app(name: String)
    case website(url: String)
    
    func open() {
        switch self {
        case .website(let urlString):
            let cleanedLocation = urlString.replacingOccurrences(of: "https://", with: "", options: .caseInsensitive)
            if let url = URL(string: "https://\(cleanedLocation)") {
                NSWorkspace.shared.open(url)
            }
        case .app(let name):
            let path = "/Applications/\(name).app"
            if let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
               let url = URL(string: "file://" + encodedPath) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

/// For when the button is to open a website, use [openAction = .website] and pass the URL in [location] without the HTTPS tag
/// When using an app, ensure the app is in the Applications folder on your Mac and then just pass the name of the app (case sensitive) in [location]
/// Custom SF Symbols must be added to the assets and then passed through, if you don't want to use existing SF Symbols
struct BookmarksCard: View {
    @State private var bookmarks = BookmarkStorage.load()

    var body: some View {
        Card {
            HStack(spacing: 10) {
                ForEach(bookmarks) { bookmark in
                    Button(action: { bookmark.openAction.open() }) {
                        VStack(spacing: 6) {
                            Image(systemName: bookmark.systemImage)
                                .font(.system(size: 16))
                                .foregroundColor(.middark)
                            Text(bookmark.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.middark)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    }
                    .buttonStyle(.glass)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(5)
        }
        .onAppear {
            bookmarks = BookmarkStorage.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("BookmarksUpdated"))) { _ in
            bookmarks = BookmarkStorage.load()
        }
    }
}
