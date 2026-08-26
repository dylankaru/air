//
//  ToDoCard.swift
//  air
//
//  Created by Dylan Karunanayake on 28/7/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ToDoItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var text: String
    var isDone: Bool = false
}

struct ToDoCard: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    let title = "Things to do:"
    private let filename = "todos.json"

    @State private var items: [ToDoItem] = []
    @State private var newTask: String = ""
    @State private var draggedItem: ToDoItem?
    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .foregroundColor(theme.textColour)
                    .font(.headline)
                
                ForEach($items) { $item in
                    ToDoRow(item: $item, draggedItem: $draggedItem) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            items.removeAll { $0.id == item.id }
                        }
                        saveItems()
                    }
                    .onDrop(
                        of: [UTType.text],
                        delegate: ToDoDropDelegate(
                            item: item,
                            items: $items,
                            draggedItem: $draggedItem
                        )
                    )
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
                .foregroundColor(theme.textColour)

            TextField("I'm listening :)", text: $newTask)
                .textFieldStyle(.plain)
                .focused($fieldIsFocused)
                .onSubmit(addTask)
                .submitLabel(.done)
                .foregroundColor(theme.textColour)
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
    @AppStorage("air_theme") private var theme: Theme = .light
    
    @Binding var item: ToDoItem
    @Binding var draggedItem: ToDoItem?
    var onDelete: () -> Void

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editText = ""

    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    item.isDone.toggle()
                }
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .foregroundColor(item.isDone ? .accentColor : theme.textColour.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundColor(theme.textColour)
                    .focused($fieldIsFocused)
                    .onSubmit {
                        finishEditing()
                    }
                    .onExitCommand {
                        cancelEditing()
                    }
            } else {
                Text(item.text)
                    .font(.subheadline)
                    .foregroundColor(item.isDone ? theme.textColour.opacity(0.4) : theme.textColour)
                    .strikethrough(item.isDone, color: theme.textColour.opacity(0.4))
                    .lineLimit(1)
                    .onTapGesture(count: 2) {
                        startEditing()
                    }
            }
            
            Spacer(minLength: 0)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(theme.textColour.opacity(0.5))
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
        .draggable(item.id.uuidString) {
//            draggedItem = item
            return Text(item.text)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    draggedItem = item
                }
        )
    }

    private func startEditing() {
        editText = item.text
        isEditing = true

        DispatchQueue.main.async {
            fieldIsFocused = true
        }
    }

    private func finishEditing() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            cancelEditing()
            return
        }

        item.text = trimmed
        isEditing = false
        fieldIsFocused = false
    }

    private func cancelEditing() {
        isEditing = false
        fieldIsFocused = false
    }
}

private struct ToDoDropDelegate: DropDelegate {
    let item: ToDoItem
    @Binding var items: [ToDoItem]
    @Binding var draggedItem: ToDoItem?

    func dropEntered(info: DropInfo) {
        guard let draggedItem else { return }
        guard draggedItem != item else { return }

        guard let fromIndex = items.firstIndex(of: draggedItem),
              let toIndex = items.firstIndex(of: item)
        else {
            return
        }

        withAnimation(.easeOut(duration: 0.15)) {
            items.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
}
