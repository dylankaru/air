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

    private let columns = 20
    private let rows = 14

    var body: some View {
        SettingsPanel(name: "Card Layout") {
            Section("Layout") {
                Button("Toggle Edit Mode") {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        layoutStore.isEditMode.toggle()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                Button("Reset All to Default", role: .destructive) {
                    layoutStore.resetAll()
                    conflicts.removeAll()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            ForEach(appCards) { card in
                Section(card.title ?? card.key.capitalized) {
                    rowContent(for: card)
                }
            }
        }
    }

    @ViewBuilder
    private func rowContent(for card: CardItem) -> some View {
        let current = layoutStore.override(for: card)

        Toggle("Show Card", isOn: Binding(
                get: {
                    current.isVisible
                },
                set: { newValue in
                    layoutStore.update(
                        key: card.key,
                        default: current
                    ) {
                        $0.isVisible = newValue
                    }

                    conflicts[card.key] = nil
                }
            )
        )

        if current.isVisible {
            Stepper( "Start Column: \(current.colStart)") {
                attempt(card) { existing in
                    var updated = existing

                    if updated.colStart <
                        updated.colEnd - card.minColSpan {

                        updated.colStart += 1
                    }

                    return updated
                }
            } onDecrement: {
                attempt(card) { existing in
                    var updated = existing

                    if updated.colStart > 0 {
                        updated.colStart -= 1
                    }

                    return updated
                }
            }

            Stepper("End Column: \(current.colEnd)") {
                attempt(card) { existing in
                    var updated = existing

                    if updated.colEnd < columns {
                        updated.colEnd += 1
                    }

                    return updated
                }
            } onDecrement: {
                attempt(card) { existing in
                    var updated = existing

                    if updated.colEnd >
                        updated.colStart + card.minColSpan {

                        updated.colEnd -= 1
                    }

                    return updated
                }
            }

            Stepper("Start Row: \(current.rowStart)") {
                attempt(card) { existing in
                    var updated = existing

                    if updated.rowStart <
                        updated.rowEnd - card.minRowSpan {

                        updated.rowStart += 1
                    }

                    return updated
                }
            } onDecrement: {
                attempt(card) { existing in
                    var updated = existing

                    if updated.rowStart > 0 {
                        updated.rowStart -= 1
                    }

                    return updated
                }
            }

            Stepper("End Row: \(current.rowEnd)") {
                attempt(card) { existing in
                    var updated = existing

                    if updated.rowEnd < rows {
                        updated.rowEnd += 1
                    }

                    return updated
                }
            } onDecrement: {
                attempt(card) { existing in
                    var updated = existing

                    if updated.rowEnd >
                        updated.rowStart + card.minRowSpan {

                        updated.rowEnd -= 1
                    }

                    return updated
                }
            }

            if let message = conflicts[card.key] {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button("Reset This Card") {
                layoutStore.reset(key: card.key)
                conflicts[card.key] = nil
            }
            .font(.caption)
        }
    }

    private func attempt(_ card: CardItem,_ transform: @escaping (CardLayoutOverride) -> CardLayoutOverride) {
        if let blocker = layoutStore.tryUpdateLinked(card: card, in: appCards, transform) {
            conflicts[card.key] =
                "Overlaps \(blocker.title ?? blocker.key.capitalized)"
        } else {
            conflicts[card.key] = nil
        }
    }
}
