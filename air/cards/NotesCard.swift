//
//  ToDoCard.swift
//  air
//
//  Created by Dylan Karunanayake on 28/7/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct NoteItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var text: String
    var isDone: Bool = false
    var indentLevel: Int = 0
}

struct NotePage: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var content: String = ""
}

struct NotesCard: View {
    @AppStorage("notes_pages_data") private var pagesData: Data = Data()
    @AppStorage("air_theme") private var theme: Theme = .light
    
    @State private var itemsByPage: [Int: [NoteItem]] = [:]
    @State private var newTask: String = ""
    @State private var draggedItem: NoteItem?
    
    @State private var pages: [NotePage] = []
    @State private var currentPageIndex: Int = 0
    
    @FocusState private var fieldIsFocused: Bool
    
    private let filename = "todos.json"
    
    private var currentItems: [NoteItem] {
        get { itemsByPage[currentPageIndex] ?? [] }
        set { itemsByPage[currentPageIndex] = newValue }
    }
    
    var body: some View {
        Card {
            if pages.isEmpty {
                ContentUnavailableView(
                    "No Pages",
                    systemImage: "note.text",
                    description: Text("Add a page in settings.")
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(pages[safe: currentPageIndex]?.title ?? "Notes")
                            .foregroundColor(theme.textColour)
                            .font(.headline)
                            .padding(.leading, 10)
                            .backgroundStyle(Color.clear)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(currentPageIndex + 1)/\(pages.count)")
                                .font(.caption)
                                .foregroundColor(theme.textColour.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .conditionalGlassEffect()
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    guard !pages.isEmpty else { return }
                                    currentPageIndex = (currentPageIndex - 1 + pages.count) % pages.count
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .conditionalGlassButton()
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    guard !pages.isEmpty else { return }
                                    currentPageIndex = (currentPageIndex + 1) % pages.count
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                            }
                            .conditionalGlassButton()
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
                }
            }
        }
        .onAppear {
            loadPages()
            loadItems()
        }
        .onChange(of: pagesData) { _, _ in
            loadPages()
        }
        .onChange(of: itemsByPage) { _, _ in
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
        
        var list = itemsByPage[currentPageIndex] ?? []
        withAnimation(.easeOut(duration: 0.15)) {
            list.append(NoteItem(text: trimmed))
        }
        itemsByPage[currentPageIndex] = list
        newTask = ""
        fieldIsFocused = true
        saveItems()
    }
    
    private func binding(for item: NoteItem) -> Binding<NoteItem> {
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
    
    private func bindingForCurrentList() -> Binding<[NoteItem]> {
        Binding(
            get: { self.itemsByPage[self.currentPageIndex] ?? [] },
            set: { updatedList in
                self.itemsByPage[self.currentPageIndex] = updatedList
                self.saveItems()
            }
        )
    }

    private func loadPages() {
        if let decoded = try? JSONDecoder().decode([NotePage].self, from: pagesData), !decoded.isEmpty {
            pages = decoded
        } else {
            // Default pages if settings haven't been configured yet
            pages = [
                NotePage(title: "Things to do:"),
                NotePage(title: "Quick notes:"),
                NotePage(title: "Others:")
            ]
        }
        
        // Clamp current page index if a page was deleted in settings
        if currentPageIndex >= pages.count {
            currentPageIndex = max(0, pages.count - 1)
        }
    }

    private func loadItems() {
        if let rawDict = JSONManager.load([String: [NoteItem]].self, from: filename) {
            var converted: [Int: [NoteItem]] = [:]
            for (key, value) in rawDict {
                if let intKey = Int(key) {
                    converted[intKey] = value
                }
            }
            itemsByPage = converted
        } else if let loaded = JSONManager.load([Int: [NoteItem]].self, from: filename) {
            itemsByPage = loaded
        } else {
            itemsByPage = [:]
        }
    }

    private func saveItems() {
        var stringKeyedDict: [String: [NoteItem]] = [:]
        for (key, value) in itemsByPage {
            stringKeyedDict[String(key)] = value
        }
        try? JSONManager.save(stringKeyedDict, to: filename)
    }
}

private struct ToDoRow: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    @Binding var item: NoteItem
    @Binding var draggedItem: NoteItem?
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
                    .onKeyPress(keys: [.tab]) { press in
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                            if press.modifiers.contains(.option) {
                                item.indentLevel = max(0, item.indentLevel - 1)
                            } else {
                                item.indentLevel = min(4, item.indentLevel + 1)
                            }
                        }
                        return .handled
                    }
            
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
        .padding(.leading, CGFloat(item.indentLevel * 24))
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
    let item: NoteItem
    @Binding var items: [NoteItem]
    @Binding var draggedItem: NoteItem?

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
