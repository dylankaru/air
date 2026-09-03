//
//  ClipboardCard.swift
//  air
//
//  Created by Dylan Karunanayake on 20/8/2026.
//

import SwiftUI
internal import Combine

enum ClipboardStorage {
    static let filename = "clipboard_history.json"
    
    static func clear() {
        try? JSONManager.delete(filename, location: .cache)
        NotificationCenter.default.post(name: .clearClipboardCache, object: nil)
    }
}

struct ClipboardCard: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    let pasteboard = NSPasteboard.general
    private let filename = ClipboardStorage.filename
    
    @State var clipboardHistory: [String] = []
    @State private var lastChangeCount: Int = NSPasteboard.general.changeCount
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                if clipboardHistory.isEmpty {
                    VStack {
                        Spacer()
                        Text("Nothing in the clipboard yet")
                            .foregroundColor(theme.textColour)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("This card tracks clipboard history while air is open")
                            .foregroundColor(theme.textColour)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(clipboardHistory, id: \.self) { item in
                                ClipboardCardRow(item: item) {
                                    copyToClipboard(text: item)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear(perform: loadCache)
        .onReceive(timer) { _ in
            getClipboardElement()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clearClipboardCache)) { _ in
            withAnimation {
                clipboardHistory.removeAll()
            }
        }
    }
    
    func getClipboardElement() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let newString = pasteboard.string(forType: .string), !newString.isEmpty {
            if clipboardHistory.first != newString {
                clipboardHistory.removeAll { $0 == newString }
                clipboardHistory.insert(newString, at: 0)
                
                if clipboardHistory.count > 50 {
                    clipboardHistory = Array(clipboardHistory.prefix(50))
                }
                
                saveCache()
            }
        }
    }
    
    private func copyToClipboard(text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
    
    private func loadCache() {
        clipboardHistory = JSONManager.load([String].self, from: filename, location: .cache) ?? []
    }
    
    private func saveCache() {
        try? JSONManager.save(clipboardHistory, to: filename, location: .cache)
    }
    
    func clearCache() {
        withAnimation {
            clipboardHistory.removeAll()
        }
        try? JSONManager.delete(filename, location: .cache)
    }
}

struct ClipboardCardRow: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    let item: String
    let onCopy: () -> Void
    
    @State private var isCopied = false
    
    var formattedText: String {
        item.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " // ")
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(formattedText)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                onCopy()
                
                withAnimation {
                    isCopied = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isCopied = false
                    }
                }
            }) {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(isCopied ? .green : .white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(theme.textVariety == TextVariety.dark ? theme.textColour.opacity(0.8) : theme.textColour.opacity(0.4))
        .cornerRadius(8)
    }
}
