//
//  ListGeneratorSettingsPanel.swift
//  air
//
//  Created by Dylan Karunanayake on 4/9/2026.
//

import SwiftUI

let listGeneratorConfigFilename = "list_generator_config.json"
let listGeneratorConfigDidChangeNotification = Notification.Name("listGeneratorConfigDidChange")
let listGeneratorHistoryDidClearNotification = Notification.Name("listGeneratorHistoryDidClear")

enum AutoGenInterval: String, Codable, CaseIterable, Identifiable {
    case off = "Off"
    case hourly = "Hourly"
    case daily = "Daily"
    case weekly = "Weekly"

    var id: String { rawValue }

    var timeInterval: TimeInterval? {
        switch self {
        case .off: return nil
        case .hourly: return 3600
        case .daily: return 86400
        case .weekly: return 604800
        }
    }
}

struct UserGeneratorConfig: Codable {
    var listTitle: String = "My List"
    var generateCount: Int = 3
    var items: [DefaultListItem] = []
    var ruleBlocks: [RuleBlock] = []
    var autoGenerationInterval: AutoGenInterval = .off
}

struct ListGeneratorSettingsPanel: View {
    @State private var config = UserGeneratorConfig()
    
    @State private var newItemTitle: String = ""
    @State private var newItemCategory: String = "General"
    @State private var showingClearHistoryConfirm = false
    
    var body: some View {
        SettingsPanel(name: "List Generator") {
            Section() {
                TextField("List Title", text: $config.listTitle)
                    .textFieldStyle(.roundedBorder)
                
                Stepper("Items per generation: \(config.generateCount)", value: $config.generateCount, in: 1...10)
                
                Picker("Auto Generate", selection: $config.autoGenerationInterval) {
                    ForEach(AutoGenInterval.allCases) { interval in
                        Text(interval.rawValue).tag(interval)
                    }
                }
            } header : {
                Text("Configuration")
            } footer: {
                if config.autoGenerationInterval != .off {
                    Text("A new list will be generated and saved automatically once per \(config.autoGenerationInterval.rawValue.lowercased()) period.")
                } else {
                    Text("Auto generate will periodically trigger the generation of your list.")
                }
            }
            
            Section {
                VStack {
                    HStack {
                        TextField("Item name", text: $newItemTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    Spacer()
                    
                    HStack {
                        TextField("Category", text: $newItemCategory)
                            .textFieldStyle(.roundedBorder)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .opacity(0)
                    }
                }
                
                if config.items.isEmpty {
                    Text("No items added yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(config.items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                Text(item.category)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: { removeItem(item) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Items")
                    Spacer()
                    Text("\(config.items.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("Items added here make up the pool the generator picks from.")
            }
            
            Section {
                if config.ruleBlocks.isEmpty {
                    Text("No rules added.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach($config.ruleBlocks) { $block in
                        RuleBlockRow(block: $block, onDelete: { removeRule(block) })
                    }
                }
                
                Menu {
                    ForEach(RuleBlock.Kind.allCases) { kind in
                        Button(kind.rawValue) { addRule(kind: kind) }
                    }
                } label: {
                    Label("Add Rule", systemImage: "plus.circle.fill")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } header: {
                Text("Rules")
            } footer: {
                VStack {
                    Text("Rules dictate how generations can occur, allowing for the odds of any element to increase or decrease.")
                }
            }
            
            Section("Clear Data") {
                Button(role: .destructive) {
                    showingClearHistoryConfirm = true
                } label: {
                    Label("Clear History Data", systemImage: "trash")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            if let loaded = JSONManager.load(UserGeneratorConfig.self, from: listGeneratorConfigFilename) {
                config = loaded
            }
        }
        .onChange(of: config.listTitle) { _, _ in saveConfig() }
        .onChange(of: config.generateCount) { _, _ in saveConfig() }
        .onChange(of: config.items) { _, _ in saveConfig() }
        .onChange(of: config.ruleBlocks) { _, _ in saveConfig() }
        .onChange(of: config.autoGenerationInterval) { _, _ in saveConfig() }
        .confirmationDialog(
            "Clear History Data?",
            isPresented: $showingClearHistoryConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your saved list generation history. This can't be undone.")
        }
    }
    
    private func saveConfig() {
        do {
            try JSONManager.save(config, to: listGeneratorConfigFilename)
            NotificationCenter.default.post(name: listGeneratorConfigDidChangeNotification, object: nil)
        } catch {
            print("Failed to save list generator config: \(error)")
        }
    }
    
    private func addItem() {
        let trimmedTitle = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        
        let item = DefaultListItem(
            title: trimmedTitle,
            category: newItemCategory.trimmingCharacters(in: .whitespaces).isEmpty ? "General" : newItemCategory
        )
        config.items.append(item)
        newItemTitle = ""
    }
    
    private func removeItem(_ item: DefaultListItem) {
        config.items.removeAll(where: { $0.id == item.id })
    }
    
    private func addRule(kind: RuleBlock.Kind) {
        config.ruleBlocks.append(RuleBlock(kind: kind))
    }
    
    private func removeRule(_ block: RuleBlock) {
        config.ruleBlocks.removeAll(where: { $0.id == block.id })
    }
    
    private func clearHistory() {
        do {
            try JSONManager.delete("default_list_history.json")
        } catch {
            print("Failed to clear history: \(error)")
        }
        NotificationCenter.default.post(name: listGeneratorHistoryDidClearNotification, object: nil)
    }
}

private struct RuleBlockRow: View {
    @Binding var block: RuleBlock
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(block.kind.rawValue)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            Text(block.kind.helpText)
                .font(.caption2)
                .foregroundColor(.secondary)

            switch block.kind {
            case .noDuplicates:
                EmptyView()
                
            case .cooldown, .categoryRest:
                HStack {
                    Text("Wait \(block.intParam) generation\(block.intParam == 1 ? "" : "s")")
                    Spacer()
                    Stepper("", value: $block.intParam, in: 1...50)
                        .labelsHidden()
                }
                .font(.caption)
                
            case .categoryBalance:
                HStack {
                    Text("Max \(block.percentParam)% of picks")
                    Spacer()
                    Stepper("", value: $block.percentParam, in: 5...100, step: 5)
                        .labelsHidden()
                }
                .font(.caption)
                
                Toggle("Limit to recent generations", isOn: $block.useWindow)
                    .font(.caption)
                
                if block.useWindow {
                    HStack {
                        Text("Over the last \(block.windowParam) generation\(block.windowParam == 1 ? "" : "s")")
                        Spacer()
                        Stepper("", value: $block.windowParam, in: 1...50)
                            .labelsHidden()
                    }
                    .font(.caption)
                }
                
            case .excludeKeyword:
                TextField("Keyword to exclude", text: $block.textParam)
                    .font(.caption)
            }

            Text(block.summary)
                .font(.caption)
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 4)
    }
}
