//
//  ListGenerator.swift
//  air
//
//  Created by Dylan Karunanayake on 4/9/2026.
//

import Foundation

struct ListRule<T> {
    let name: String
    let validate: (_ history: [[T]], _ current: [T], _ candidate: T) -> Bool
    
    init(_ name: String, _ check: @escaping (_ history: [[T]], _ current: [T], _ candidate: T) -> Bool) {
        self.name = name
        self.validate = check
    }
}

extension ListRule where T: Equatable {
    static var noDuplicates: ListRule<T> {
        ListRule("No Duplicates") { _, current, candidate in
            !current.contains(candidate)
        }
    }
}

extension ListRule where T: Identifiable {
    static func itemCooldown(window: Int) -> ListRule<T> {
        ListRule("Cooldown of \(window) generations") { history, _, candidate in
            let recentSessions = history.suffix(window).flatMap { $0 }
            return !recentSessions.contains(where: { $0.id == candidate.id })
        }
    }
    
    static func attributeRest<V: Equatable>(window: Int, keyPath: KeyPath<T, V>) -> ListRule<T> {
        ListRule("Attribute rest of \(window) generations") { history, _, candidate in
            let recentValues = history.suffix(window).flatMap { $0 }.map { $0[keyPath: keyPath] }
            return !recentValues.contains(candidate[keyPath: keyPath])
        }
    }
}

extension ListRule {
    /// Caps how much of a given attribute value is allowed to make up the picks.
    /// If `window` is nil, balances over all-time history. If set, only considers
    /// the last `window` generations plus the current in-progress one.
    static func attributeBalance<V: Hashable>(
        maxRatio: Double,
        keyPath: KeyPath<T, V>,
        window: Int? = nil
    ) -> ListRule<T> {
        ListRule("Attribute Balance") { history, current, candidate in
            let relevantHistory = window != nil ? Array(history.suffix(window!)) : history
            let totalHistory = relevantHistory.flatMap { $0 } + current
            guard !totalHistory.isEmpty else { return true }
            
            let matchCount = totalHistory.filter { $0[keyPath: keyPath] == candidate[keyPath: keyPath] }.count
            let ratio = Double(matchCount + 1) / Double(totalHistory.count + 1)
            return ratio <= maxRatio
        }
    }
}

struct GeneratorState<T: Codable>: Codable {
    var history: [[T]] = []
    var lastGenerationDate: Date? = nil
}

final class ListGenerator<T: Codable & Identifiable> {
    private(set) var history: [[T]] = []
    private(set) var lastGenerationDate: Date? = nil
    private let storageFilename: String?
    private let maxHistoryWindow: Int
    
    init(storageFilename: String? = nil, maxHistoryWindow: Int = 14) {
        self.storageFilename = storageFilename
        self.maxHistoryWindow = maxHistoryWindow
        
        if let filename = storageFilename,
           let state = JSONManager.load(GeneratorState<T>.self, from: filename) {
            self.history = state.history
            self.lastGenerationDate = state.lastGenerationDate
        }
    }
    
    func generate(from pool: [T], count: Int, rules: [ListRule<T>] = []) -> [T] {
        var result: [T] = []
        let candidatePool = pool.shuffled()
        
        for candidate in candidatePool {
            if result.count >= count { break }
            
            let passesAllRules = rules.allSatisfy { rule in
                rule.validate(history, result, candidate)
            }
            
            if passesAllRules {
                result.append(candidate)
            }
        }
        
        return result
    }
    
    func commit(_ session: [T]) {
        history.append(session)
        
        if history.count > maxHistoryWindow {
            history = Array(history.suffix(maxHistoryWindow))
        }
        
        lastGenerationDate = Date()
        persist()
    }
    
    func reset() {
        history = []
        lastGenerationDate = nil
        if let filename = storageFilename {
            try? JSONManager.delete(filename)
        }
    }
    
    func shouldAutoGenerate(interval: TimeInterval) -> Bool {
        guard let last = lastGenerationDate else { return true }
        return Date().timeIntervalSince(last) >= interval
    }
    
    private func persist() {
        guard let filename = storageFilename else { return }
        let state = GeneratorState(history: history, lastGenerationDate: lastGenerationDate)
        do {
            try JSONManager.save(state, to: filename)
        } catch {
            print("Failed to save generation history: \(error)")
        }
    }
}
