//
//  BookmarksSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 23/8/2026.
//

import SwiftUI

struct BookmarkStorage {
    private static let key = "SavedBookmarks"
    
    static func load() -> [BookmarkItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([BookmarkItem].self, from: data) else {
            return [
                BookmarkItem(title: "GitHub", systemImage: "chevron.left.slash.chevron.right", openAction: .website(url: "github.com")),
                BookmarkItem(title: "Vercel", systemImage: "triangle.fill", openAction: .website(url: "vercel.com")),
                BookmarkItem(title: "Discord", systemImage: "bubble.left.fill", openAction: .app(name: "Discord")),
                BookmarkItem(title: "Hack Club", systemImage: "globe", openAction: .website(url: "hackclub.com"))
            ]
        }
        return decoded
    }
    
    static func save(_ items: [BookmarkItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: key)
            NotificationCenter.default.post(name: Notification.Name("BookmarksUpdated"), object: nil)
        }
    }
}

struct BookmarksSettingsPanel: View {
    @State private var bookmarks = BookmarkStorage.load()

    var body: some View {
        SettingsPanel(name: "Bookmarks") {
            Section(
                header: Text("Manage Bookmarks"),
                footer: VStack(alignment: .leading, spacing: 4) {
                        Text("You can configure up to 4 bookmarks to fit the card layout (\(bookmarks.count)/4).")
                        Text("When settings the address of your bookmark, if it is a website, add the URL to the website without the HTTPS protocol. If it is an app, put the full case sensitive name of the app as it is found in the Applications folder.")
                            .foregroundColor(.secondary)
                    }
            ) {
                ForEach($bookmarks.indices, id: \.self) { index in
                    BookmarkRowView(bookmark: $bookmarks[index]) {
                        bookmarks.remove(at: index)
                        BookmarkStorage.save(bookmarks)
                    }
                }
                
                if bookmarks.count < 4 {
                    Button(action: {
                        let newBookmark = BookmarkItem(title: "New Bookmark", systemImage: "globe", openAction: .website(url: "example.com"))
                        bookmarks.append(newBookmark)
                        BookmarkStorage.save(bookmarks)
                    }) {
                        Label("Add Bookmark", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onChange(of: bookmarks) { _, newBookmarks in
            BookmarkStorage.save(newBookmarks)
        }
    }
}

struct BookmarkRowView: View {
    @Binding var bookmark: BookmarkItem
    var onDelete: () -> Void
    
    @State private var isWebsite: Bool
    @State private var targetValue: String

    init(bookmark: Binding<BookmarkItem>, onDelete: @escaping () -> Void) {
        self._bookmark = bookmark
        self.onDelete = onDelete
        
        let initialIsWebsite: Bool
        let initialTarget: String
        switch bookmark.wrappedValue.openAction {
        case .website(let url):
            initialIsWebsite = true
            initialTarget = url
        case .app(let name):
            initialIsWebsite = false
            initialTarget = name
        }
        _isWebsite = State(initialValue: initialIsWebsite)
        _targetValue = State(initialValue: initialTarget)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: bookmark.systemImage.isEmpty ? "globe" : bookmark.systemImage)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(bookmark.title)
                    .foregroundColor(.white)
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .help("Delete Bookmark")
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Title")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                TextField("Name", text: $bookmark.title)
                    .textFieldStyle(.roundedBorder)
            }
            
                VStack(alignment: .leading, spacing: 2) {
                    Text("Icon")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Icon name", text: $bookmark.systemImage)
                        .textFieldStyle(.roundedBorder)
                }
                
            VStack(alignment: .leading, spacing: 2) {
                Text("Type")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Picker("Type of Bookmark", selection: $isWebsite) {
                    Text("Website").tag(true)
                    Text("App").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: isWebsite) { _, newValue in
                    updateAction(isWebsite: newValue, value: targetValue)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Location")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                TextField(isWebsite ? "Website URL" : "Mac App Name", text: $targetValue)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: targetValue) { _, newValue in
                        updateAction(isWebsite: isWebsite, value: newValue)
                    }
            }
        }
        .padding(.vertical, 6)
    }

    private func updateAction(isWebsite: Bool, value: String) {
        if isWebsite {
            bookmark.openAction = .website(url: value)
        } else {
            bookmark.openAction = .app(name: value)
        }
    }
}
