//
//  ListGeneratorCard.swift
//  air
//
//  Created by Dylan Karunanayake on 4/9/2026.
//

import SwiftUI
internal import Combine

struct DefaultListItem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let category: String
    
    init(id: String = UUID().uuidString, title: String, category: String = "General") {
        self.id = id
        self.title = title
        self.category = category
    }
}

struct ListGeneratorCard<T: Codable & Identifiable, RowContent: View>: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    let title: String
    let pool: [T]
    let generateCount: Int
    let autoGenerationInterval: TimeInterval?
    let ruleProvider: () -> [ListRule<T>]
    let rowContent: (T) -> RowContent
    
    @State private var generator: ListGenerator<T>
    @State private var generatedItems: [T] = []
    @State private var historyCount: Int = 0
    @State private var isShowingAutoResult: Bool = false
    @State private var justCommitted: Bool = false

    init(
        title: String = "List Generator",
        pool: [T] = [],
        generateCount: Int = 3,
        storageFilename: String? = nil,
        maxHistoryWindow: Int = 14,
        autoGenerationInterval: TimeInterval? = nil,
        rules: @escaping () -> [ListRule<T>] = { [] },
        @ViewBuilder rowContent: @escaping (T) -> RowContent
    ) {
        self.title = title
        self.pool = pool
        self.generateCount = generateCount
        self.autoGenerationInterval = autoGenerationInterval
        self.ruleProvider = rules
        self.rowContent = rowContent
        
        _generator = State(initialValue: ListGenerator<T>(
            storageFilename: storageFilename,
            maxHistoryWindow: maxHistoryWindow
        ))
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundColor(theme.textColour)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(theme.textColour)
                    Spacer()
                    Text("History: \(historyCount)")
                        .font(.caption2)
                        .foregroundColor(theme.textColour)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(6)
                }

                Divider().opacity(0)
                
                if pool.isEmpty {
                    Text("No items in pool. Configure in settings.")
                        .font(.caption)
                        .foregroundColor(theme.textColour.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if justCommitted && generatedItems.isEmpty {
                    Button(action: { runGeneration(auto: false) }) {
                        Label("New Generation", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(pool.isEmpty)
                }

                if !generatedItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Generated Output")
                                .font(.subheadline)
                                .foregroundColor(theme.textColour.opacity(0.8))
                            if isShowingAutoResult {
                                Text("Auto-generated")
                                    .font(.caption2)
                                    .foregroundColor(theme.textColour)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }

                        ForEach(generatedItems) { item in
                            rowContent(item)
                        }

                        if !isShowingAutoResult {
                            Divider().opacity(0)
                            
                            Button(action: { runGeneration(auto: false) }) {
                                Label("Regenerate List", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(pool.isEmpty)
                            Button(action: commitAndSave) {
                                Label("Accept & Save", systemImage: "tray.and.arrow.down.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .padding(.top, 4)
                        }
                    }
                }

                if !generator.history.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("History")
                            .font(.subheadline)
                            .foregroundColor(theme.textColour.opacity(0.8))

                        ForEach(indexedHistory, id: \.index) { entry in
                            historyRow(index: entry.index, session: entry.session)
                        }
                    }
                } else if generatedItems.isEmpty && !justCommitted {
                    Text("No history yet. Generate and save a list to see it here.")
                        .font(.caption)
                        .foregroundColor(theme.textColour.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .onAppear {
            historyCount = generator.history.count
            
            runGeneration(auto: false)
            checkAutoGenerate()
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            checkAutoGenerate()
        }
        .onReceive(NotificationCenter.default.publisher(for: listGeneratorHistoryDidClearNotification)) { _ in
            generator.reset()
            historyCount = 0
            generatedItems = []
            justCommitted = false
        }
    }

    private var indexedHistory: [(index: Int, session: [T])] {
        var result: [(index: Int, session: [T])] = []
        result.reserveCapacity(generator.history.count)
        for (i, session) in generator.history.enumerated() {
            result.append((index: i, session: session))
        }
        return result.reversed()
    }

    @ViewBuilder
    private func historyRow(index: Int, session: [T]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Generation #\(index + 1)")
                .font(.caption2)
                .foregroundColor(theme.textColour.opacity(0.6))

            ForEach(session) { item in
                rowContent(item)
            }
        }
        .padding(8)
        .background(.clear)
        .cornerRadius(8)
    }

    private func runGeneration(auto: Bool) {
        generatedItems = generator.generate(
            from: pool,
            count: generateCount,
            rules: ruleProvider()
        )
        isShowingAutoResult = auto
        justCommitted = false
        if auto {
            generator.commit(generatedItems)
            historyCount = generator.history.count
        }
    }

    private func commitAndSave() {
        generator.commit(generatedItems)
        historyCount = generator.history.count
        generatedItems = []
        justCommitted = true
    }

    private func checkAutoGenerate() {
        guard let interval = autoGenerationInterval, !pool.isEmpty else { return }
        guard generator.shouldAutoGenerate(interval: interval) else { return }
        runGeneration(auto: true)
    }
}

struct DefaultListGeneratorCard: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    @State private var config: UserGeneratorConfig = {
        JSONManager.load(UserGeneratorConfig.self, from: listGeneratorConfigFilename) ?? UserGeneratorConfig()
    }()

    var body: some View {
        ListGeneratorCard<DefaultListItem, HStack<TupleView<(Text, Spacer, Text)>>>(
            title: config.listTitle,
            pool: config.items,
            generateCount: config.generateCount,
            storageFilename: "default_list_history.json",
            autoGenerationInterval: config.autoGenerationInterval.timeInterval,
            rules: { buildRules(from: config.ruleBlocks) },
            rowContent: { item in
                HStack {
                    Text(item.title)
                        .foregroundColor(theme.textColour)
                    Spacer()
                    Text(item.category)
                        .font(.caption)
                        .foregroundColor(theme.textColour.opacity(0.6))
                }
            }
        )
        .id(config.items.map { $0.id }.joined())
        .onAppear(perform: reloadConfig)
        .onReceive(NotificationCenter.default.publisher(for: listGeneratorConfigDidChangeNotification)) { _ in
            reloadConfig()
        }
    }

    private func reloadConfig() {
        if let loaded = JSONManager.load(UserGeneratorConfig.self, from: listGeneratorConfigFilename) {
            config = loaded
        }
    }
}

extension ListGeneratorCard where T == DefaultListItem, RowContent == HStack<TupleView<(Text, Spacer, Text)>> {
    init() {
        fatalError("Use DefaultListGeneratorCard() instead of ListGeneratorCard() for the default item type.")
    }
}
