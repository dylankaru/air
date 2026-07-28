//
//  ContentView.swift
//  air
//
//  Created by Dylan Karunanayake on 22/7/2026.
//

import SwiftUI

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

struct ColumnSpanKey: LayoutValueKey {
    static let defaultValue: Int = 1
}

struct RowSpanKey: LayoutValueKey {
    static let defaultValue: Int = 1
}

extension View {
    func gridColumnSpan(_ span: Int) -> some View {
        layoutValue(key: ColumnSpanKey.self, value: span)
    }
    func gridRowSpan(_ span: Int) -> some View {
        layoutValue(key: RowSpanKey.self, value: span)
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

        var occupied = Array(repeating: Array(repeating: false, count: rows), count: columns)

        for subview in subviews {
            let colSpan = min(columns, max(1, subview[ColumnSpanKey.self]))
            let rowSpan = min(rows, max(1, subview[RowSpanKey.self]))

            if let (startCol, startRow) = findSlot(colSpan: colSpan, rowSpan: rowSpan, occupied: occupied) {
                for c in startCol..<(startCol + colSpan) {
                    for r in startRow..<(startRow + rowSpan) {
                        occupied[c][r] = true
                    }
                }

                let x = bounds.minX + CGFloat(startCol) * (cellWidth + spacing)
                let y = bounds.minY + CGFloat(startRow) * (cellHeight + spacing)
                let width = CGFloat(colSpan) * cellWidth + CGFloat(colSpan - 1) * spacing
                let height = CGFloat(rowSpan) * cellHeight + CGFloat(rowSpan - 1) * spacing

                subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: width, height: height)
                )
            }
        }
    }

    private func findSlot(colSpan: Int, rowSpan: Int, occupied: [[Bool]]) -> (Int, Int)? {
        guard rows >= rowSpan, columns >= colSpan else { return nil }

        for r in 0...(rows - rowSpan) {
            for c in 0...(columns - colSpan) {
                var fits = true
                for dc in 0..<colSpan {
                    for dr in 0..<rowSpan {
                        if occupied[c + dc][r + dr] {
                            fits = false
                            break
                        }
                    }
                    if !fits { break }
                }
                if fits { return (c, r) }
            }
        }
        return nil
    }
}

struct CardItem: Identifiable {
    let id = UUID()
    let colSpan: Int
    let rowSpan: Int
    let content: AnyView
    
    init<Content: View>(
            colSpan: Int,
            rowSpan: Int,
            @ViewBuilder content: () -> Content
        ) {
            self.colSpan = colSpan
            self.rowSpan = rowSpan
            self.content = AnyView(content())
        }
}

struct ContentView: View {
    let isVisible: Bool = true
    
    let columns = 12
    let rows = 12

    let items: [CardItem] = [
        CardItem(colSpan: 4, rowSpan: 2) {
            GreetingCard()
        },
        CardItem(colSpan: 2, rowSpan: 2) {
            WeatherCard()
        }
    ]
    
    // TODO: fix the issue where the card is setting its own dimensions

    var body: some View {
            NavigationStack {
                ZStack {
                    Color.beige.ignoresSafeArea()

                    Masonry(columns: columns, rows: rows, spacing: 6) {
                        ForEach(items) { item in
                            item.content
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .gridColumnSpan(item.colSpan)
                                .gridRowSpan(item.rowSpan)
                        }
                    }
//                    .padding(10)
//                    .background(isVisible ? Color.orange.opacity(0.2) : Color.clear)
//                    .padding(10)
                }
            }
        }
}

#Preview {
    ContentView()
}
