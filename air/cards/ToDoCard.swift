//
//  ToDoCard.swift
//  air
//
//  Created by Dylan Karunanayake on 28/7/2026.
//

import SwiftUI

struct ToDoItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var text: String
    var isDone: Bool = false
}

struct ToDoCard: View {

    let title = "Things to do:"
    private let filename = "todos.json"

    @State private var items: [ToDoItem] = []
    @State private var newTask: String = ""
    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .foregroundStyle(Color.middark)
                    .font(.headline)

                ForEach($items) { $item in
                    ToDoRow(item: $item) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            items.removeAll { $0.id == item.id }
                        }
                        saveItems()
                    }
                }

                addTaskRow
            }
            .padding(10)
        }
        .onAppear(perform: loadItems)
        .onAppear {
            DispatchQueue.main.async {
                fieldIsFocused = false
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .onChange(of: items) { _, _ in
            saveItems()
        }
    }

    private var addTaskRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.subheadline)
                .foregroundStyle(Color.middark)

            TextField("Let me know what's on ur mind", text: $newTask)
                .textFieldStyle(.plain)
                .foregroundColor(.middark)
                .focused($fieldIsFocused)
                .onSubmit(addTask)
                .submitLabel(.done)
        }
        .contentShape(Rectangle())
        .onTapGesture { fieldIsFocused = true }
    }

    private func addTask() {
        let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            items.append(ToDoItem(text: trimmed))
        }
        newTask = ""
        fieldIsFocused = true
    }

    private func loadItems() {
        items = JSONManager.load([ToDoItem].self, from: filename) ?? []
    }

    private func saveItems() {
        try? JSONManager.save(items, to: filename)
    }
}

private struct ToDoRow: View {
    @Binding var item: ToDoItem
    var onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    item.isDone.toggle()
                }
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .foregroundStyle(item.isDone ? Color.accentColor : Color.middark.opacity(0.5))
            }
            .buttonStyle(.plain)

            Text(item.text)
                .font(.subheadline)
                .foregroundStyle(item.isDone ? Color.middark.opacity(0.4) : Color.middark)
                .strikethrough(item.isDone, color: Color.middark.opacity(0.4))
                .lineLimit(1)

            Spacer(minLength: 0)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.middark.opacity(0.5))
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
}
