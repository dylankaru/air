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

struct NotesCard: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    @State private var itemsByPage: [Int: [ToDoItem]] = [:]
    @State private var newTask: String = ""
    @State private var draggedItem: ToDoItem?
    
    @State private var currentPageIndex: Int = 0
    private let totalPages: Int = 3
    
    @FocusState private var fieldIsFocused: Bool
    
    let title = ["Things to do:", "Quick notes:", "Others:"]
    private let filename = "todos.json"
    
    private var currentItems: [ToDoItem] {
        get { itemsByPage[currentPageIndex] ?? [] }
        set { itemsByPage[currentPageIndex] = newValue }
    }
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title[currentPageIndex])
                        .foregroundColor(theme.textColour)
                        .font(.headline)
                        .padding(.leading, 10)
                        .backgroundStyle(Color.clear)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(currentPageIndex + 1)/\(totalPages)")
                            .font(.caption)
                            .foregroundColor(theme.textColour.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassEffect(.regular.interactive())
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentPageIndex = (currentPageIndex - 1 + totalPages) % totalPages
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.glass)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentPageIndex = (currentPageIndex + 1) % totalPages
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.glass)
                    }
                    .padding(.trailing, 10)
                }
                .padding(.top, 10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        
                        ForEach(currentItems) { item in
                            ToDoRow(
                                item: binding(for: item),
                                draggedItem: $draggedItem
                            ) {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    var list = itemsByPage[currentPageIndex] ?? []
                                    list.removeAll { $0.id == item.id }
                                    itemsByPage[currentPageIndex] = list
                                }
                                saveItems()
                            }
                            .onDrop(
                                of: [UTType.text],
                                delegate: ToDoDropDelegate(
                                    item: item,
                                    items: bindingForCurrentList(),
                                    draggedItem: $draggedItem
                                )
                            )
                        }
                        
                        addTaskRow
                    }
                    .padding(.leading, 10)
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.hidden)
                .onAppear(perform: loadItems)
                .onChange(of: itemsByPage) { _, _ in
                    saveItems()
                }
            }
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
        
        var list = itemsByPage[currentPageIndex] ?? []
        withAnimation(.easeOut(duration: 0.15)) {
            list.append(ToDoItem(text: trimmed))
        }
        itemsByPage[currentPageIndex] = list
        newTask = ""
        fieldIsFocused = true
        saveItems()
    }
    
    // FIX 3: Explicit dictionary value assignment for mutations
    private func binding(for item: ToDoItem) -> Binding<ToDoItem> {
        Binding(
            get: {
                self.itemsByPage[self.currentPageIndex]?.first(where: { $0.id == item.id }) ?? item
            },
            set: { updatedItem in
                var list = self.itemsByPage[self.currentPageIndex] ?? []
                if let index = list.firstIndex(where: { $0.id == item.id }) {
                    list[index] = updatedItem
                    self.itemsByPage[self.currentPageIndex] = list
                    self.saveItems()
                }
            }
        )
    }
    
    private func bindingForCurrentList() -> Binding<[ToDoItem]> {
        Binding(
            get: { self.itemsByPage[self.currentPageIndex] ?? [] },
            set: { updatedList in
                self.itemsByPage[self.currentPageIndex] = updatedList
                self.saveItems()
            }
        )
    }

    private func loadItems() {
        if let loaded = JSONManager.load([Int: [ToDoItem]].self, from: filename) {
            itemsByPage = loaded
        } else {
            itemsByPage = [:]
        }
    }

    private func saveItems() {
        try? JSONManager.save(itemsByPage, to: filename)
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
                    .onSubmit { finishEditing() }
                    .onExitCommand { cancelEditing() }
            } else {
                Text(item.text)
                    .font(.subheadline)
                    .foregroundColor(item.isDone ? theme.textColour.opacity(0.4) : theme.textColour)
                    .strikethrough(item.isDone, color: theme.textColour.opacity(0.4))
                    .multilineTextAlignment(.leading)
                    .onTapGesture(count: 2) { startEditing() }
            }
            
            Spacer(minLength: 0)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(theme.textColour.opacity(0.5))
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
            .padding(.trailing, 10)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
        .draggable(item.id.uuidString) {
            Text(item.text)
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
        else { return }

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
