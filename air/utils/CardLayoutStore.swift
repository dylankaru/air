//
//  CardLayoutStore.swift
//  air
//
//  Created by Dylan Karunanayake on 24/8/2026.
//

import SwiftUI
internal import Combine

struct CardLayoutOverride: Encodable, Decodable {
    var colStart: Int
    var colEnd: Int
    var rowStart: Int
    var rowEnd: Int
    var isVisible: Bool
    
    func clamped(columns: Int, rows: Int, minColSpan: Int = 1, minRowSpan: Int = 1) -> CardLayoutOverride {
        var s = self
        let minCols = max(1, minColSpan)
        let minRows = max(1, minRowSpan)
        s.colStart = max(0, min(s.colStart, columns - minCols))
        s.colEnd = max(s.colStart + minCols, min(s.colEnd, columns))
        s.rowStart = max(0, min(s.rowStart, rows - minRows))
        s.rowEnd = max(s.rowStart + minRows, min(s.rowEnd, rows))
        return s
    }
}

class CardLayoutStore: ObservableObject {
    static let shared = CardLayoutStore()
    static let fixedKeys: Set<String> = ["greeting"]
    
    /// Which space's layout is currently active. ContentView keeps this in sync
    /// with `activeSpace.id` whenever the user switches spaces. Every method
    /// below reads/writes overrides scoped to this space automatically, so
    /// callers (EditHandleOverlay, settings panels, etc.) don't need to know
    /// about spaces at all — their calls are unchanged from before spaces existed.
    @Published var currentSpaceId: UUID
    
    @Published private(set) var overrides: [String: CardLayoutOverride] = [:]
    @Published var isEditMode: Bool = false
    @Published private(set) var shortcuts: [String: KeyBinding] = [:]
    
    private let filename = "air_card_layout.json"
    private let shortcutsFilename = "air_shortcuts.json"
    
    private var dragBackup: [String: CardLayoutOverride]? = nil
    
    init() {
        // Fall back to a stable placeholder if SpacesManager hasn't loaded any
        // spaces yet; ContentView.onAppear sets the real value immediately.
        currentSpaceId = SpacesManager.shared.spaces.first?.id ?? UUID()
        load()
        loadShortcuts()
    }
    
    // MARK: - Key namespacing (internal only — nothing outside this file needs to know)
    
    private func storageKey(_ cardKey: String) -> String {
        "\(currentSpaceId.uuidString)_\(cardKey)"
    }
    
    func override(for card: CardItem) -> CardLayoutOverride {
        overrides[storageKey(card.key)] ?? CardLayoutOverride(colStart: card.colStart, colEnd: card.colEnd, rowStart: card.rowStart, rowEnd: card.rowEnd, isVisible: card.startsVisible)
    }
    
    func update(key: String, default defaultOverride: CardLayoutOverride, _ transform: (inout CardLayoutOverride) -> Void) {
        let k = storageKey(key)
        var current = overrides[k] ?? defaultOverride
        transform(&current)
        overrides[k] = current
        save()
    }
    
    func reset(key: String) {
        overrides.removeValue(forKey: storageKey(key))
        save()
    }
    
    func resetAll() {
        let prefix = currentSpaceId.uuidString + "_"
        for k in overrides.keys where k.hasPrefix(prefix) {
            overrides.removeValue(forKey: k)
        }
        save()
    }
    
    func findAvailablePosition(for card: CardItem, in cards: [CardItem], columns: Int, rows: Int) -> CardLayoutOverride? {
        let colSpan = max(card.minColSpan, card.colEnd - card.colStart)
        let rowSpan = max(card.minRowSpan, card.rowEnd - card.rowStart)
        
        let occupied: [(colStart: Int, colEnd: Int, rowStart: Int, rowEnd: Int)] = cards
            .filter { $0.key != card.key }
            .compactMap { other in
                let o = override(for: other)
                guard o.isVisible else { return nil }
                return (o.colStart, o.colEnd, o.rowStart, o.rowEnd)
            }
        
        func overlaps(_ r: (colStart: Int, colEnd: Int, rowStart: Int, rowEnd: Int)) -> Bool {
            occupied.contains { o in
                r.colStart < o.colEnd && o.colStart < r.colEnd &&
                r.rowStart < o.rowEnd && o.rowStart < r.rowEnd
            }
        }
        
        guard rowSpan <= rows, colSpan <= columns else { return nil }
        
        for rowStart in 0...(rows - rowSpan) {
            for colStart in 0...(columns - colSpan) {
                let candidate = (colStart, colStart + colSpan, rowStart, rowStart + rowSpan)
                if !overlaps(candidate) {
                    return CardLayoutOverride(
                        colStart: candidate.0,
                        colEnd: candidate.1,
                        rowStart: candidate.2,
                        rowEnd: candidate.3,
                        isVisible: true
                    )
                }
            }
        }
        
        return nil
    }
    
    func effectiveCards(from cards: [CardItem]) -> [CardItem] {
        cards.compactMap { card in
            guard let o = overrides[storageKey(card.key)] else {
                return card.startsVisible ? card : nil
            }
            guard o.isVisible else { return nil }
            var updated = card
            updated.colStart = o.colStart
            updated.colEnd = o.colEnd
            updated.rowStart = o.rowStart
            updated.rowEnd = o.rowEnd
            return updated
        }
    }
    
    func beginInteractiveEdit() {
        if dragBackup == nil {
            dragBackup = overrides
        }
    }
    
    func commitInteractiveEdit() {
        dragBackup = nil
        save()
    }
    
    func cancelInteractiveEdit() {
        if let backup = dragBackup {
            overrides = backup
        }
        dragBackup = nil
    }
    
    func previewMove(card: CardItem, colDelta: Int, rowDelta: Int, in cards: [CardItem], columns: Int, rows: Int) {
        guard !Self.fixedKeys.contains(card.key), let backup = dragBackup else { return }
        
        overrides = backup
        
        let cardKey = storageKey(card.key)
        let before = backup[cardKey] ?? override(for: card)
        let colSpan = before.colEnd - before.colStart
        let rowSpan = before.rowEnd - before.rowStart
        
        var after = before
        after.colStart = before.colStart + colDelta
        after.colEnd = after.colStart + colSpan
        after.rowStart = before.rowStart + rowDelta
        after.rowEnd = after.rowStart + rowSpan
        after = after.clamped(columns: columns, rows: rows, minColSpan: card.minColSpan, minRowSpan: card.minRowSpan)
        
        guard after.colEnd - after.colStart == colSpan, after.rowEnd - after.rowStart == rowSpan else { return }
        
        let overlapping = cards.filter { other in
            guard other.key != card.key, !Self.fixedKeys.contains(other.key) else { return false }
            let o = backup[storageKey(other.key)] ?? override(for: other)
            guard o.isVisible else { return false }
            let colOverlap = after.colStart < o.colEnd && o.colStart < after.colEnd
            let rowOverlap = after.rowStart < o.rowEnd && o.rowStart < after.rowEnd
            return colOverlap && rowOverlap
        }
        
        if overlapping.isEmpty {
            overrides[cardKey] = after
            return
        }
        
        guard overlapping.count == 1, let blocker = overlapping.first else { return }
        let blockerKey = storageKey(blocker.key)
        let blockerOverride = backup[blockerKey] ?? override(for: blocker)
        let blockerSpanMatches =
        (blockerOverride.colEnd - blockerOverride.colStart == colSpan) &&
        (blockerOverride.rowEnd - blockerOverride.rowStart == rowSpan)
        guard blockerSpanMatches else { return }
        
        var swapped = blockerOverride
        swapped.colStart = before.colStart
        swapped.colEnd = before.colEnd
        swapped.rowStart = before.rowStart
        swapped.rowEnd = before.rowEnd
        
        overrides[cardKey] = after
        overrides[blockerKey] = swapped
    }
    
    func previewResize(card: CardItem, colDelta: Int, rowDelta: Int, in cards: [CardItem], columns: Int, rows: Int) {
        guard let backup = dragBackup else { return }
        overrides = backup
        
        var bestCol = 0
        var bestRow = 0
        
        if colDelta != 0 {
            let step = colDelta > 0 ? 1 : -1
            var d = 0
            while d != colDelta {
                let next = d + step
                overrides = backup
                let blocked = tryUpdateLinked(card: card, in: cards) {
                    var u = $0; u.colEnd += next; return u
                }
                if blocked != nil { break }
                d = next
            }
            bestCol = d
        }
        
        if rowDelta != 0 {
            let step = rowDelta > 0 ? 1 : -1
            var d = 0
            while d != rowDelta {
                let next = d + step
                overrides = backup
                let blocked = tryUpdateLinked(card: card, in: cards, commit: false) {
                    var u = $0; u.colEnd += bestCol; u.rowEnd += next; return u
                }
                if blocked != nil { break }
                d = next
            }
            bestRow = d
        }
        
        
        overrides = backup
        tryUpdateLinked(card: card, in: cards, commit: false) {
            var u = $0; u.colEnd += bestCol; u.rowEnd += bestRow; return u
        }
    }
    
    func setEditMode(_ value: Bool) {
        DispatchQueue.main.async { [weak self] in
            withAnimation(.easeInOut(duration: 0.5)) {
                self?.isEditMode = value
                if !value {
                    self?.cancelInteractiveEdit()
                }
            }
        }
    }
    
    private func cardsThatShareEdges(of card: CardItem, before: CardLayoutOverride, after: CardLayoutOverride, in cards: [CardItem] ) -> [(key: String, apply: (CardLayoutOverride) -> CardLayoutOverride)] {
        var results: [(String, (CardLayoutOverride) -> CardLayoutOverride)] = []
        
        func rowsOverlap(_ a: CardLayoutOverride, _ b: CardLayoutOverride) -> Bool {
            a.rowStart < b.rowEnd && b.rowStart < a.rowEnd
        }
        
        func colsOverlap(_ a: CardLayoutOverride, _ b: CardLayoutOverride) -> Bool {
            a.colStart < b.colEnd && b.colStart < a.colEnd
        }
        
        for other in cards where other.key != card.key && !CardLayoutStore.fixedKeys.contains(other.key) {
            let o = override(for: other)
            
            if before.colEnd != after.colEnd, o.colStart == before.colEnd, rowsOverlap(before, o) {
                results.append((other.key, { existing in
                    var updated = existing
                    updated.colStart = after.colEnd
                    return updated
                }))
            }
            
            if before.colStart != after.colStart, o.colEnd == before.colStart, rowsOverlap(before, o) {
                results.append((other.key, { existing in
                    var updated = existing
                    updated.colEnd = after.colStart
                    return updated
                }))
            }
            
            if before.rowEnd != after.rowEnd, o.rowStart == before.rowEnd, colsOverlap(before, o) {
                results.append((other.key, { existing in
                    var updated = existing
                    updated.rowStart = after.rowEnd
                    return updated
                }))
            }
            
            if before.rowStart != after.rowStart, o.rowEnd == before.rowStart, colsOverlap(before, o) {
                results.append((other.key, { existing in
                    var updated = existing
                    updated.rowEnd = after.rowStart
                    return updated
                }))
            }
        }
        return results
    }
    
    @discardableResult
    func tryUpdateLinked(card: CardItem, in cards: [CardItem], commit: Bool = true,_ transform: (CardLayoutOverride) -> CardLayoutOverride) -> CardItem? {
        guard !Self.fixedKeys.contains(card.key) else { return nil }
        
        let before = override(for: card)
        let rawAfter = transform(before)

        let after = rawAfter.clamped(columns: 20, rows: 14, minColSpan: card.minColSpan, minRowSpan: card.minRowSpan)
        
        let linked = cardsThatShareEdges(of: card, before: before, after: after, in: cards)
        let linkedKeys = Set(linked.map(\.key) + [card.key])
        
        // Candidates are keyed by the plain card key (not the namespaced
        // storage key) since that's what overlap-checking below needs;
        // translated to namespaced keys only at the final write.
        var candidates: [String: CardLayoutOverride] = [card.key: after]
        
        for (key, apply) in linked {
            guard let neighborCard = cards.first(where: { $0.key == key }) else { continue }
            let neighborBefore = override(for: neighborCard)
            let neighborRaw = apply(neighborBefore)
            
            let neighborColSpan = neighborRaw.colEnd - neighborRaw.colStart
            let neighborRowSpan = neighborRaw.rowEnd - neighborRaw.rowStart
            guard neighborColSpan >= max(1, neighborCard.minColSpan),
                  neighborRowSpan >= max(1, neighborCard.minRowSpan) else {
                return neighborCard
            }
            
            candidates[key] = neighborRaw.clamped(columns: 20, rows: 14, minColSpan: neighborCard.minColSpan, minRowSpan: neighborCard.minRowSpan)
        }
        
        for other in cards where !linkedKeys.contains(other.key) {
            let o = override(for: other)
            guard o.isVisible else { continue }
            for (_, candidate) in candidates {
                guard candidate.isVisible else { continue }
                let colOverlap = candidate.colStart < o.colEnd && o.colStart < candidate.colEnd
                let rowOverlap = candidate.rowStart < o.rowEnd && o.rowStart < candidate.rowEnd
                if colOverlap && rowOverlap {
                    return other
                }
            }
        }
        
        for (key, value) in candidates {
            overrides[storageKey(key)] = value
        }
        if commit { save() }
        return nil
    }
    
    func shortcut(for actionKey: String, default defaultBinding: KeyBinding) -> KeyBinding {
        shortcuts[actionKey] ?? defaultBinding
    }
    
    func setShortcut(_ binding: KeyBinding, for actionKey: String) {
        shortcuts[actionKey] = binding
        saveShortcuts()
    }
    
    func resetShortcut(for actionKey: String) {
        shortcuts.removeValue(forKey: actionKey)
        saveShortcuts()
    }
    
    func resetAllShortcuts() {
        shortcuts.removeAll()
        saveShortcuts()
    }
    
    private func loadShortcuts() {
        shortcuts = JSONManager.load([String: KeyBinding].self, from: shortcutsFilename, location: .applicationSupport) ?? [:]
    }
    
    private func saveShortcuts() {
        try? JSONManager.save(shortcuts, to: shortcutsFilename, location: .applicationSupport)
    }
    
    private func load() {
        overrides = JSONManager.load([String: CardLayoutOverride].self, from: filename, location: .applicationSupport) ?? [:]
    }
    
    private func save() {
        try? JSONManager.save(overrides, to: filename, location: .applicationSupport)
    }
}
