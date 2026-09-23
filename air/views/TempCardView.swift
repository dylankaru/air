//
//  TempCardView.swift
//  air
//
//  Created by Dylan Karunanayake on 21/9/2026.
//

import SwiftUI

struct TempCardView: View {
    @Binding var isPresented: Bool
    let containerSize: CGSize
    
    @State private var searchText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var selectedIndex: Int? = nil
    @State private var activeCard: CardItem? = nil
    
    private let columns = 20
    private let rows = 14
    private let gridSpacing: CGFloat = 10
    
    private let sizeMultiplier: CGFloat = 1.15
    private let horizontalMargin: CGFloat = 80
    private let verticalMargin: CGFloat = 160
    
    var filteredItems: [CardItem] {
        let rawQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let baseCards = appCards.filter { $0.key != "greeting" }
        
        if rawQuery.isEmpty {
            return baseCards
        }
        
        let terms = rawQuery.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        return baseCards.filter { card in
            let title = card.title
            let keyCleaned = card.key.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
            let keywordsString = (card.keywords ?? []).joined(separator: " ")
            
            let searchableContent = "\(title) \(card.key) \(keyCleaned) \(keywordsString)".lowercased()
            
            return terms.allSatisfy { term in
                searchableContent.contains(term)
            }
        }
    }
    
    private func baseSize(for card: CardItem) -> CGSize {
        let cellW = (containerSize.width - 20 - CGFloat(columns - 1) * gridSpacing) / CGFloat(columns)
        let cellH = (containerSize.height - 26 - CGFloat(rows - 1) * gridSpacing) / CGFloat(rows)
        
        let colSpan = CGFloat(max(1, card.colEnd - card.colStart))
        let rowSpan = CGFloat(max(1, card.rowEnd - card.rowStart))
        
        return CGSize(
            width: max(1, colSpan * cellW + (colSpan - 1) * gridSpacing),
            height: max(1, rowSpan * cellH + (rowSpan - 1) * gridSpacing)
        )
    }
    
    private func zoom(for base: CGSize) -> CGFloat {
        let maxW = containerSize.width - horizontalMargin * 2
        let maxH = containerSize.height - verticalMargin * 2
        return max(0.1, min(sizeMultiplier, maxW / base.width, maxH / base.height))
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(alignment: .center, spacing: 0) {
                if let card = activeCard {
                    let base = baseSize(for: card)
                    let z = zoom(for: base)
                    
                    card.content
                        .if(!card.ignoreEdgePadding) { view in
                            view.edgePadding(colStart: card.colStart, colEnd: card.colEnd, maxColumns: columns)
                        }
                        .frame(width: base.width, height: base.height)
                        .scaleEffect(z)
                        .frame(width: base.width * z, height: base.height * z)
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        TextField("Search for cards", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.title3)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                executeSelection()
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text("ESC")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    
                    Divider().opacity(0.2)
                    
                    if filteredItems.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No results found")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 280)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 4) {
                                    ForEach(Array(filteredItems.enumerated()), id: \.element.key) { index, item in
                                        CardOptionRow(
                                            item: item,
                                            isSelected: selectedIndex == index,
                                            onSelect: { selectItem(item) },
                                            onHover: { hovering in
                                                if hovering {
                                                    selectedIndex = index
                                                }
                                            }
                                        )
                                        .id(item.id)
                                    }
                                }
                                .padding(8)
                            }
                            .frame(maxHeight: 280)
                            .onChange(of: selectedIndex) { _, newIndex in
                                if let newIndex {
                                    proxy.scrollTo(newIndex, anchor: nil)
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            HStack {
                                Text("↑↓")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                                Text("TAB")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                            }
                            Text("Navigate").font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Text("↵")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                            Text("Open").font(.caption2)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text("ESC")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                            Text("Dismiss").font(.caption2)
                        }
                    }
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.15))
                }
            }
            .frame(width: activeCard == nil ? 540 : nil)
            .if(activeCard == nil) { view in
                view
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.bottom, 100)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: activeCard?.key)
        .onAppear {
            isTextFieldFocused = true
        }
        .onChange(of: searchText) {
            selectedIndex = nil
        }
        .onKeyPress(.downArrow) {
            guard activeCard == nil else { return .ignored }
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard activeCard == nil else { return .ignored }
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.tab) {
            guard activeCard == nil else { return .ignored }
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            guard activeCard == nil else { return .ignored }
            executeSelection()
            return .handled
        }
        .onKeyPress(.escape) {
            if activeCard != nil {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    activeCard = nil
                    isTextFieldFocused = true
                }
            } else {
                dismiss()
            }
            return .handled
        }
    }
    
    private func moveSelection(by delta: Int) {
        guard !filteredItems.isEmpty else { return }
        let count = filteredItems.count
        
        if let current = selectedIndex {
            selectedIndex = (current + delta + count) % count
        } else {
            selectedIndex = delta > 0 ? 0 : count - 1
        }
    }
    
    private func executeSelection() {
        guard let index = selectedIndex, filteredItems.indices.contains(index) else { return }
        selectItem(filteredItems[index])
    }
    
    private func dismiss() {
        isPresented = false
    }
    
    private func selectItem(_ item: CardItem) {
        activeCard = item
    }
}

struct CardOptionRow: View {
    let item: CardItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 20)
                
                Text(item.title)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    isSelected
                    ? Color.accentColor
                    : (isHovered ? Color.primary.opacity(0.08) : Color.clear)
                )
        )
        .onHover { hovering in
            isHovered = hovering
            onHover(hovering)
        }
    }
}
