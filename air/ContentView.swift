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

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case news = "News"
    case weather = "Weather"
    case streak = "Streak"
    case audio = "Audio"
    case timer = "Timer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .news: return "newspaper.fill"
        case .weather: return "cloud.fog"
        case .streak: return "flame.fill"
        case .audio: return "waveform"
        case .timer: return "clock.badge.fill"
        }
    }
}


let appCards: [CardItem] = [
    CardItem(
        key: "greeting",
        colStart: 0, colEnd: 6, rowStart: 0, rowEnd: 2,
        ignoreEdgePadding: true, ignoreStandardArrangements: true
    ) { GreetingCard() },
    CardItem(
        key: "weather",
        title: "Weather", icon: "cloud.fog.fill",
        colStart: 6, colEnd: 13, rowStart: 0, rowEnd: 2,
        minColSpan: 4, minRowSpan: 2,
        settingsView: { WeatherSettingsView() }
    ) { WeatherCard() },
    CardItem(
        key: "todo",
        colStart: 13, colEnd: 20, rowStart: 0, rowEnd: 4,
        minColSpan: 3, minRowSpan: 3
    ) { ToDoCard() },
    CardItem(
        key: "news",
        title: "News", icon: "newspaper.fill",
        colStart: 6, colEnd: 13, rowStart: 2, rowEnd: 7,
        minColSpan: 3, minRowSpan: 3,
        settingsView: { NewsSettingsView() }
    ) { NewsCard() },
    CardItem(
        key: "streak",
        title: "Streak", icon: "flame.fill",
        colStart: 13, colEnd: 20, rowStart: 4, rowEnd: 7,
        minColSpan: 2, minRowSpan: 2,
        settingsView: { StreakSettingsView() }
    ) { StreakCard() },
    CardItem(
        key: "audio",
        title: "Audio Player", icon: "person.spatialaudio.fill",
        colStart: 0, colEnd: 6, rowStart: 2, rowEnd: 7,
        minColSpan: 3, minRowSpan: 3,
        settingsView: { AudioPlayerSettingsView() }
    ) { AudioPlayerCard() },
    CardItem(
        key: "timer", title: "Timer", icon: "clock.badge.fill",
        colStart: 0, colEnd: 6, rowStart: 7, rowEnd: 11,
        minColSpan: 2, minRowSpan: 2,
        settingsView: { TimerSettingsView() }
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
        settingsView: { SpeedTestSettingsView() }
    ) { SpeedTestCard() },
    CardItem(
        key: "clipboard",
        title: "Clipboard", icon: "sparkle.text.clipboard.fill",
        colStart: 0, colEnd: 6, rowStart: 11, rowEnd: 14,
        minColSpan: 2, minRowSpan: 2,
        settingsView: { ClipboardSettingsView() }
    ) { ClipboardCard() },
    CardItem(
        key: "bookmarks",
        title: "Bookmarks", icon: "bookmark.fill",
        colStart: 6, colEnd: 10, rowStart: 7, rowEnd: 9,
        minColSpan: 3, minRowSpan: 2,
        settingsView: { BookmarksSettingsView() }
    ) { BookmarksCard() },
    CardItem(
        key: "systemstats",
        colStart: 13, colEnd: 20, rowStart: 7, rowEnd: 14,
        minColSpan: 3, minRowSpan: 3
    ) { SystemStatsCard() }
]

extension View {
    func edgePadding(colStart: Int, colEnd: Int, maxColumns: Int = 20, paddingAmount: CGFloat = 16) -> some View {
        self
            .padding(.leading, colStart == 0 ? paddingAmount : 0)
            .padding(.trailing, colEnd == maxColumns ? paddingAmount : 0)
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

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

extension View {
    func gridColumn(_ start: Int, _ end: Int) -> some View {
        layoutValue(key: ColStartKey.self, value: start)
            .layoutValue(key: ColEndKey.self, value: end)
    }
    func gridRow(_ start: Int, _ end: Int) -> some View {
        layoutValue(key: RowStartKey.self, value: start)
            .layoutValue(key: RowEndKey.self, value: end)
    }
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
    let settingsView: AnyView?
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
        @ViewBuilder settingsView: () -> SettingsContent = { EmptyView() },
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
        self.settingsView = AnyView(settingsView())
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
