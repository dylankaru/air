//
//  EditHandleOverlay.swift
//  air
//
//  Created by Dylan Karunanayake on 24/8/2026.
//

import SwiftUI

struct EditHandleOverlay: View {
    let card: CardItem
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let columns: Int
    let rows: Int

    @ObservedObject private var layoutStore = CardLayoutStore.shared

    @State private var isDragging = false
    @State private var lastColDelta = 0
    @State private var lastRowDelta = 0

    private var cellWidth: CGFloat {
        cardWidth + 10
    }

    private var cellHeight: CGFloat {
        cardHeight + 10
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 11)
            .stroke(
                isDragging ? Color.accentColor : Color.green,
                lineWidth: 2
            )
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        Color.accentColor.opacity(
                            isDragging ? 0.10 : 0
                        )
                    )
            )
            .overlay(alignment: .bottomTrailing) {
                ResizeHandle()
                    .padding(4)
                    .highPriorityGesture(resizeGesture)
            }
            .contentShape(Rectangle())
            .gesture(moveGesture)
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .named(EditGrid.coordinateSpaceName))
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    lastColDelta = 0
                    lastRowDelta = 0
                    layoutStore.beginInteractiveEdit()
                }

                let colDelta = Int((value.translation.width / cellWidth).rounded())

                let rowDelta = Int((value.translation.height / cellHeight).rounded())

                guard colDelta != lastColDelta || rowDelta != lastRowDelta else { return }

                lastColDelta = colDelta
                lastRowDelta = rowDelta

                layoutStore.previewMove(card: card, colDelta: colDelta, rowDelta: rowDelta, in: appCards, columns: columns, rows: rows)
            }
            .onEnded { _ in
                isDragging = false
                lastColDelta = 0
                lastRowDelta = 0

                withAnimation(.spring(response: 0.20, dampingFraction: 0.9)) {
                    layoutStore.commitInteractiveEdit()
                }
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .named(EditGrid.coordinateSpaceName))
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    lastColDelta = 0
                    lastRowDelta = 0
                    layoutStore.beginInteractiveEdit()
                }
                
                let colDelta = Int((value.translation.width / cellWidth).rounded())
                
                let rowDelta = Int((value.translation.height / cellHeight).rounded())
                
                guard colDelta != lastColDelta || rowDelta != lastRowDelta else { return }
                
                lastColDelta = colDelta
                lastRowDelta = rowDelta
                
                layoutStore.previewResize(card: card, colDelta: colDelta, rowDelta: rowDelta, in: appCards, columns: columns, rows: rows)
            }
            .onEnded { _ in
                isDragging = false
                lastColDelta = 0
                lastRowDelta = 0
                
                withAnimation(.spring(response: 0.20, dampingFraction: 0.9)) {
                    layoutStore.commitInteractiveEdit()
                }
            }
    }

    private func ResizeHandle() -> some View {
        Circle()
            .fill(Color.green)
            .frame(width: 14, height: 14)
            .overlay {
                Circle()
                    .stroke(.white, lineWidth: 2)
            }
            .frame(width: 24, height: 24)
            .contentShape(Circle())
    }
}
