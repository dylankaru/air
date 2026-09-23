//
//  SpacesSettingsPanel.swift
//  air
//
//  Created by Dylan Karunanayake on 23/9/2026.
//

import SwiftUI

struct SpacesSettingsPanel: View {
    @ObservedObject private var spacesManager = SpacesManager.shared
    
    @State private var isAddingSpace = false
    @State private var newSpaceName = ""
    @State private var newSpaceCardKeys: Set<String> = []
    @State private var newSpaceTheme: Theme = .light
    
    @State private var editingSpaceId: UUID? = nil
    @State private var editingName = ""
    
    private var assignableCards: [CardItem] {
        appCards.filter { $0.key != "greeting" }
    }
    
    var body: some View {
        SettingsPanel(name: "Spaces") {
            Section("Keybinds") {
                KeybindSetting(
                    label: "Next Space",
                    actionKey: "nextSpace",
                    defaultBinding: .nextSpaceDefault
                )
                KeybindSetting(
                    label: "Previous Space",
                    actionKey: "previousSpace",
                    defaultBinding: .previousSpaceDefault
                )
            }
            
            Section("Your Spaces") {
                ForEach(spacesManager.spaces) { space in
                    spaceRow(for: space)
                }
            }
            
            Section {
                if isAddingSpace {
                    addSpaceForm
                } else {
                    Button {
                        newSpaceName = ""
                        newSpaceCardKeys = []
                        newSpaceTheme = .light
                        isAddingSpace = true
                    } label: {
                        Label("Add Space", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func spaceRow(for space: CardSpace) -> some View {
        if editingSpaceId == space.id {
            editSpaceForm(for: space)
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(space.name)
                        .font(.body)
                    Text("\(space.cardList.count) card\(space.cardList.count == 1 ? "" : "s") · \(space.theme.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    editingName = space.name
                    editingSpaceId = space.id
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                if spacesManager.spaces.count > 1 {
                    Button(role: .destructive) {
                        spacesManager.deleteSpace(id: space.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    @ViewBuilder
    private func editSpaceForm(for space: CardSpace) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Space name", text: $editingName)
                .textFieldStyle(.roundedBorder)
            
            Picker("Theme", selection: Binding(
                get: { space.theme },
                set: { spacesManager.setTheme($0, for: space.id) }
            )) {
                ForEach(Theme.allCases, id: \.self) { t in
                    Text(t.rawValue.capitalized).tag(t)
                }
            }
            
            Text("Cards in this space")
                .font(.caption)
                .foregroundColor(.secondary)
            
            cardChecklist(
                selected: Binding(
                    get: { Set(space.cardList.map(\.key)) },
                    set: { newKeys in
                        spacesManager.setCardKeys(Array(newKeys), for: space.id)
                    }
                )
            )
            
            HStack {
                Spacer()
                Button("Cancel") {
                    editingSpaceId = nil
                }
                Button("Done") {
                    let trimmed = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        spacesManager.renameSpace(id: space.id, to: trimmed)
                    }
                    editingSpaceId = nil
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private var addSpaceForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Space name", text: $newSpaceName)
                .textFieldStyle(.roundedBorder)
            
            Picker("Theme", selection: $newSpaceTheme) {
                ForEach(Theme.allCases, id: \.self) { t in
                    Text(t.rawValue.capitalized).tag(t)
                }
            }
            
            Text("Cards in this space")
                .font(.caption)
                .foregroundColor(.secondary)
            
            cardChecklist(selected: $newSpaceCardKeys)
            
            HStack {
                Spacer()
                Button("Cancel") {
                    isAddingSpace = false
                }
                Button("Create") {
                    let trimmed = newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let name = trimmed.isEmpty ? "New Space" : trimmed
                    spacesManager.addSpace(name: name, theme: newSpaceTheme, cardKeys: Array(newSpaceCardKeys))
                    isAddingSpace = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newSpaceCardKeys.isEmpty)
            }
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func cardChecklist(selected: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(assignableCards) { card in
                Toggle(isOn: Binding(
                    get: { selected.wrappedValue.contains(card.key) },
                    set: { isOn in
                        if isOn {
                            selected.wrappedValue.insert(card.key)
                        } else {
                            selected.wrappedValue.remove(card.key)
                        }
                    }
                )) {
                    Label(card.title, systemImage: card.icon)
                }
                .toggleStyle(.checkbox)
            }
        }
    }
}
