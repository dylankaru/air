//
//  ContentView.swift
//  air
//
//  Created by Dylan Karunanayake on 22/7/2026.
//

import SwiftUI

//

enum EditGrid {
    static let coordinateSpaceName = "editGrid"
}

let appCards: [CardItem] = [
    CardItem(
        key: "greeting",
        colStart: 0, colEnd: 6, rowStart: 0, rowEnd: 2,
        ignoreEdgePadding: true, ignoreStandardArrangements: true,
    ) { GreetingCard() },
    CardItem(
        key: "weather",
        title: "Weather", icon: "cloud.fog.fill",
        colStart: 6, colEnd: 13, rowStart: 0, rowEnd: 2,
        minColSpan: 4, minRowSpan: 2,
        settingsPanel: { WeatherSettingsPanel() }
    ) { WeatherCard() },
    CardItem(
        key: "notes",
        title: "Notes", icon: "book.pages.fill", 
        colStart: 13, colEnd: 20, rowStart: 0, rowEnd: 4,
        minColSpan: 3, minRowSpan: 3,
        settingsPanel: { NotesSettingsPanel() },
    ) { NotesCard() },
    CardItem(
        key: "news",
        title: "News", icon: "newspaper.fill",
        colStart: 6, colEnd: 13, rowStart: 2, rowEnd: 7,
        minColSpan: 3, minRowSpan: 3,
        settingsPanel: { NewsSettingsPanel() }
    ) { NewsCard() },
    CardItem(
        key: "streak",
        title: "Streak", icon: "flame.fill",
        colStart: 13, colEnd: 20, rowStart: 4, rowEnd: 7,
        minColSpan: 2, minRowSpan: 2,
        settingsPanel: { StreakSettingsPanel() }
    ) { StreakCard() },
    CardItem(
        key: "audio",
        title: "Audio Player", icon: "person.spatialaudio.fill",
        colStart: 0, colEnd: 6, rowStart: 2, rowEnd: 7,
        minColSpan: 3, minRowSpan: 3,
        settingsPanel: { AudioPlayerSettingsPanel() }
    ) { AudioPlayerCard() },
    CardItem(
        key: "timer", title: "Timer", icon: "clock.badge.fill",
        colStart: 0, colEnd: 6, rowStart: 7, rowEnd: 11,
        minColSpan: 2, minRowSpan: 2,
        settingsPanel: { TimerSettingsPanel() }
    ) { TimerCard() },
    CardItem(
        key: "calendar",
        colStart: 6, colEnd: 13, rowStart: 9, rowEnd: 14,
        minColSpan: 3, minRowSpan: 3
    ) { CalendarCard() },
    CardItem(
        key: "speedtest",
        title: "Speed Test", icon: "hare.fill",
        colStart: 10, colEnd: 13, rowStart: 7, rowEnd: 9,
        minColSpan: 2, minRowSpan: 2,
        settingsPanel: { SpeedTestSettingsPanel() }
    ) { SpeedTestCard() },
    CardItem(
        key: "clipboard",
        title: "Clipboard", icon: "sparkle.text.clipboard.fill",
        colStart: 0, colEnd: 6, rowStart: 11, rowEnd: 14,
        minColSpan: 2, minRowSpan: 2,
        settingsPanel: { ClipboardSettingsPanel() }
    ) { ClipboardCard() },
    CardItem(
        key: "bookmarks",
        title: "Bookmarks", icon: "bookmark.fill",
        colStart: 6, colEnd: 10, rowStart: 7, rowEnd: 9,
        minColSpan: 3, minRowSpan: 2,
        settingsPanel: { BookmarksSettingsPanel() }
    ) { BookmarksCard() },
    CardItem(
        key: "systemstats",
        colStart: 13, colEnd: 20, rowStart: 7, rowEnd: 14,
        minColSpan: 3, minRowSpan: 3
    ) { SystemStatsCard() }
]

struct ColStartKey: LayoutValueKey {
    nonisolated static let defaultValue: Int = 0
}
struct ColEndKey: LayoutValueKey {
    nonisolated static let defaultValue: Int = 1
}
struct RowStartKey: LayoutValueKey {
    nonisolated static let defaultValue: Int = 0
}
struct RowEndKey: LayoutValueKey {
    nonisolated static let defaultValue: Int = 1
}

struct Masonry: Layout {
    let columns: Int
    let rows: Int
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(
            width: proposal.width ?? 300,
            height: proposal.height ?? 300
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let totalSpacingX = spacing * CGFloat(columns - 1)
        let totalSpacingY = spacing * CGFloat(rows - 1)

        let cellWidth = max(0, (bounds.width - totalSpacingX) / CGFloat(columns))
        let cellHeight = max(0, (bounds.height - totalSpacingY) / CGFloat(rows))

        for subview in subviews {
            let colStart = min(max(0, subview[ColStartKey.self]), columns)
            let colEnd = min(max(colStart + 1, subview[ColEndKey.self]), columns)
            let rowStart = min(max(0, subview[RowStartKey.self]), rows)
            let rowEnd = min(max(rowStart + 1, subview[RowEndKey.self]), rows)

            let colSpan = colEnd - colStart
            let rowSpan = rowEnd - rowStart

            let x = bounds.minX + CGFloat(colStart) * (cellWidth + spacing)
            let y = bounds.minY + CGFloat(rowStart) * (cellHeight + spacing)
            let width = CGFloat(colSpan) * cellWidth + CGFloat(colSpan - 1) * spacing
            let height = CGFloat(rowSpan) * cellHeight + CGFloat(rowSpan - 1) * spacing

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: width, height: height)
            )
        }
    }
}

struct CardItem: Identifiable {
    let id = UUID()
    let key: String
    let title: String?
    let icon: String?
    var colStart: Int
    var colEnd: Int
    var rowStart: Int
    var rowEnd: Int
    let minColSpan: Int
    let minRowSpan: Int
    let ignoreEdgePadding: Bool
    let ignoreStandardArrangements: Bool
    let settingsPanel: AnyView?
    let content: AnyView?
    
    init<Content: View, SettingsContent: View>(
        key: String,
        title: String? = nil,
        icon: String? = nil,
        colStart: Int,
        colEnd: Int,
        rowStart: Int,
        rowEnd: Int,
        minColSpan: Int = 1,
        minRowSpan: Int = 1,
        ignoreEdgePadding: Bool = false,
        ignoreStandardArrangements: Bool = false,
        @ViewBuilder settingsPanel: () -> SettingsContent = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.key = key
        self.title = title
        self.icon = icon
        self.colStart = colStart
        self.colEnd = colEnd
        self.rowStart = rowStart
        self.rowEnd = rowEnd
        self.minColSpan = max(1, minColSpan)
        self.minRowSpan = max(1, minRowSpan)
        self.ignoreEdgePadding = ignoreEdgePadding
        self.ignoreStandardArrangements = ignoreStandardArrangements
        self.settingsPanel = AnyView(settingsPanel())
        self.content = AnyView(content())
    }
}

struct ContentView: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    @AppStorage("air_two_settings_buttons") private var twoButtons: Bool = false
    
    @ObservedObject private var layoutStore = CardLayoutStore.shared
    @Environment(\.openWindow) private var openWindow

    let columns = 20
    let rows = 14

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let cardWidth = (geo.size.width - 20 - CGFloat(columns - 1) * 10) / CGFloat(columns)
                let cardHeight = (geo.size.height - 26 - CGFloat(rows - 1) * 10) / CGFloat(rows)
                
                ZStack(alignment: .bottomTrailing) {
                    theme.backgroundColor.ignoresSafeArea()
                    
                    Masonry(columns: columns, rows: rows, spacing: 10) {
                        ForEach(layoutStore.effectiveCards(from: appCards)) { card in
                            ZStack {
                                card.content
                                
                                if layoutStore.isEditMode && !CardLayoutStore.fixedKeys.contains(card.key) {
                                    EditHandleOverlay(card: card, cardWidth: cardWidth, cardHeight: cardHeight, columns: columns, rows: rows)
                                    //                                        .transition(.opacity)
                                }
                            }
                            .if(!card.ignoreEdgePadding) { view in
                                view.edgePadding(colStart: card.colStart, colEnd: card.colEnd, maxColumns: columns)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .gridColumn(card.colStart, card.colEnd)
                            .gridRow(card.rowStart, card.rowEnd)
                        }
                    }
                    .padding(10)
                    .padding(.bottom, 16)
                    
                    if twoButtons {
                        SettingsButton()
                            .padding(10)
                    }
                }
                .coordinateSpace(name: EditGrid.coordinateSpaceName)
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 {
                    if layoutStore.isEditMode {
                        layoutStore.setEditMode(false)
                        return nil
                    }
                }
                return event
            }
        }
    }
    

    private func SettingsButton() -> some View {
        Button { openWindow(id: "settings-window") } label: {
            Image(systemName: "gearshape.fill")
                .font(.title)
                .foregroundColor(theme.textColour)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.airButton)
    }
}
