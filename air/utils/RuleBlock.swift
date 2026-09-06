//
//  RuleBlock.swift
//  air
//
//  Created by Dylan Karunanayake on 4/9/2026.
//

import Foundation

struct RuleBlock: Codable, Identifiable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case noDuplicates = "No Duplicates"
        case cooldown = "Item Cooldown"
        case categoryRest = "Category Rest"
        case categoryBalance = "Category Balance"
        case excludeKeyword = "Exclude Keyword"

        var id: String { rawValue }

        var helpText: String {
            switch self {
            case .noDuplicates: return "Never pick the same item twice in one generation."
            case .cooldown: return "An item can't reappear for a number of past generations."
            case .categoryRest: return "A category can't reappear for a number of past generations."
            case .categoryBalance: return "Cap how much of the pool one category can make up, either overall or within a recent window of generations."
            case .excludeKeyword: return "Skip any item whose title contains a keyword."
            }
        }
    }

    var id: String = UUID().uuidString
    var kind: Kind
    var intParam: Int = 3
    var percentParam: Int = 50
    var textParam: String = ""
    var useWindow: Bool = false
    var windowParam: Int = 5

    var summary: String {
        switch kind {
        case .noDuplicates:
            return "Never repeat an item within the same generation"
        case .cooldown:
            return "Item can't reappear for \(intParam) generation\(intParam == 1 ? "" : "s")"
        case .categoryRest:
            return "Category can't repeat for \(intParam) generation\(intParam == 1 ? "" : "s")"
        case .categoryBalance:
            if useWindow {
                return "No category over \(percentParam)% of picks in the last \(windowParam) generation\(windowParam == 1 ? "" : "s")"
            } else {
                return "No category over \(percentParam)% of all picks, ever"
            }
        case .excludeKeyword:
            return textParam.isEmpty ? "Exclude keyword (not set)" : "Exclude items containing \"\(textParam)\""
        }
    }
}

/// Converts user-facing rule blocks into the ListRule closures ListGenerator actually runs.
func buildRules(from blocks: [RuleBlock]) -> [ListRule<DefaultListItem>] {
    blocks.map { block in
        switch block.kind {
        case .noDuplicates:
            return ListRule<DefaultListItem>.noDuplicates

        case .cooldown:
            return ListRule<DefaultListItem>.itemCooldown(window: block.intParam)

        case .categoryRest:
            return ListRule<DefaultListItem>.attributeRest(window: block.intParam, keyPath: \DefaultListItem.category)

        case .categoryBalance:
            return ListRule<DefaultListItem>.attributeBalance(
                maxRatio: Double(block.percentParam) / 100.0,
                keyPath: \DefaultListItem.category,
                window: block.useWindow ? block.windowParam : nil
            )

        case .excludeKeyword:
            let keyword = block.textParam.trimmingCharacters(in: .whitespaces).lowercased()
            return ListRule<DefaultListItem>("Exclude Keyword") { _, _, candidate in
                keyword.isEmpty || !candidate.title.lowercased().contains(keyword)
            }
        }
    }
}
