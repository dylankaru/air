//
//  CardLayoutSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 24/8/2026.
//

import SwiftUI

struct CardLayoutSettingsPanel: View {
    @ObservedObject private var layoutStore = CardLayoutStore.shared
    @State private var conflicts: [String: String] = [:]
    @State private var isRecordingShortcut = false

    private var toggleableCards: [CardItem] {
        return appCards.filter { $0.key != "greeting" }
    }

    private let columns = 20
    private let rows = 14

    var body: some View {
        SettingsPanel(name: "Card Layout") {
            Section("Layout") {
                Button("Reset All to Default", role: .destructive) {
                    layoutStore.resetAll()
                    conflicts.removeAll()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Section("Edit Mode") {
                KeybindSetting(
                    label: "Toggle Edit Mode",
                    actionKey: "toggleEditMode",
                    defaultBinding: .toggleEditModeDefault
                )
            }

            Section("Card Visibility") {
                ForEach(toggleableCards) { card in
                    rowContent(for: card)
                }
            }
        }
    }

    @ViewBuilder
    private func rowContent(for card: CardItem) -> some View {
        let current = layoutStore.override(for: card)

        Toggle(card.title, isOn: Binding(
            get: { current.isVisible },
            set: { newValue in
                if newValue {
                    if let slot = layoutStore.findAvailablePosition(for: card, in: appCards, columns: columns, rows: rows) {
                        layoutStore.update(key: card.key, default: current) { existing in
                            existing = slot
                        }
                        conflicts[card.key] = nil
                    } else {
                        conflicts[card.key] = "No free space available for this card"
                    }
                } else {
                    layoutStore.update(key: card.key, default: current) {
                        $0.isVisible = false
                    }
                    conflicts[card.key] = nil
                }
            }
        ))

        if let message = conflicts[card.key] {
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
    }
}
