//
//  ContentView.swift
//  air
//
//  Created by Dylan Karunanayake on 22/7/2026.
//

import SwiftUI

//

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
        colStart: 0, colEnd: 6, rowStart: 0, rowEnd: 2,
        ignoreEdgePadding: true, ignoreStandardArrangements: true) {
        GreetingCard()
    },
    CardItem(title: "Weather", icon: "cloud.fog.fill",
             colStart: 6, colEnd: 13, rowStart: 0, rowEnd: 2,
             settingsView: { WeatherSettingsView() }
    ) {
        WeatherCard()
    },
    CardItem(
        colStart: 13, colEnd: 20, rowStart: 0, rowEnd: 4,
    ) {
        ToDoCard()
    },
    CardItem(
        title: "News", icon: "newspaper.fill",
        colStart: 6, colEnd: 13, rowStart: 2, rowEnd: 7,
        settingsView: { NewsSettingsView() }
    ) {
        NewsCard()
    },
    CardItem(
        title: "Streak", icon: "flame.fill",
        colStart: 13, colEnd: 20, rowStart: 4, rowEnd: 7,
        settingsView: { StreakSettingsView() }
    ) {
        StreakCard()
    },
    CardItem(
        title: "Audio Player", icon: "person.spatialaudio.fill",
        colStart: 0, colEnd: 6, rowStart: 2, rowEnd: 7,
        settingsView: { AudioPlayerSettingsView() }
    ) {
        AudioPlayerCard()
    },
    CardItem(
        title: "Timer", icon: "clock.badge.fill",
        colStart: 0, colEnd: 6, rowStart: 7, rowEnd: 11,
        settingsView: { TimerSettingsView() }
    ) {
        TimerCard()
    },
    CardItem(
        colStart: 6, colEnd: 13, rowStart: 9, rowEnd: 14,
    ) {
        CalendarCard()
    },
    CardItem(
        title: "Speed Test", icon: "hare.fill",
        colStart: 10, colEnd: 13, rowStart: 7, rowEnd: 9,
        settingsView: { SpeedTestSettingsView() }
    ) {
        SpeedTestCard()
    },
    CardItem(
        title: "Clipboard", icon: "sparkle.text.clipboard.fill",
        colStart: 0, colEnd: 6, rowStart: 11, rowEnd: 14,
        settingsView: { ClipboardSettingsView() }
    ) {
        ClipboardCard()
    },
    CardItem(
        title: "Bookmarks", icon: "bookmark.fill",
        colStart: 6, colEnd: 10, rowStart: 7, rowEnd: 9,
        settingsView: { BookmarksSettingsView() }
    ) {
        BookmarksCard()
    }
]

//

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
    
    static let beige = Color(hex: 0xfffeeb)
    static let widget = Color(hex: 0xF2E5C9)
    static let middark = Color(hex: 0x1D1D1D)
    static let test = Color(hex: 0xD4E0D2)
}

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
    static let defaultValue: Int = 0
}
struct ColEndKey: LayoutValueKey {
    static let defaultValue: Int = 1
}
struct RowStartKey: LayoutValueKey {
    static let defaultValue: Int = 0
}
struct RowEndKey: LayoutValueKey {
    static let defaultValue: Int = 1
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
    let title: String?
    let icon: String?
    let colStart: Int
    let colEnd: Int
    let rowStart: Int
    let rowEnd: Int
    let ignoreEdgePadding: Bool
    let ignoreStandardArrangements: Bool
    let settingsView: AnyView?
    let content: AnyView
    
    init<Content: View, SettingsContent: View>(
        title: String? = nil,
        icon: String? = nil,
        colStart: Int,
        colEnd: Int,
        rowStart: Int,
        rowEnd: Int,
        ignoreEdgePadding: Bool = false,
        ignoreStandardArrangements: Bool = false,
        @ViewBuilder settingsView: () -> SettingsContent = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.colStart = colStart
        self.colEnd = colEnd
        self.rowStart = rowStart
        self.rowEnd = rowEnd
        self.ignoreEdgePadding = ignoreEdgePadding
        self.ignoreStandardArrangements = ignoreStandardArrangements
        self.settingsView = AnyView(settingsView())
        self.content = AnyView(content())
    }
}

struct ContentView: View {
    @State private var isHovered = false
    
    @Environment(\.openWindow) private var openWindow
    
    let isVisible: Bool = true
    
    let columns = 20
    let rows = 14
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.beige.ignoresSafeArea()
                
                Masonry(columns: columns, rows: rows, spacing: 10) {
                    ForEach(appCards) { card in
                        card.content
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
                
                SettingsButton()
                    .padding(10)
            }
        }
    }
    
    private func SettingsButton() -> some View {
        Button {
            openWindow(id: "settings-window")
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title)
                .foregroundStyle(Color.middark)
                .padding(6)
                .background(Color.widget)
                .clipShape(Circle())
        }
        .buttonStyle(.airButton)
    }
}
