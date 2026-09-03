//
//  NotesSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 30/8/2026.
//

import SwiftUI

struct NotesSettingsPanel: View {
    @AppStorage("notes_pages_data") private var pagesData: Data = Data()
    @State private var pages: [NotePage] = []
    @FocusState private var focusedPageID: UUID?

    var body: some View {
        SettingsPanel(name: "Notes") {
            Section {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Pages")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: addPage) {
                                    Image(systemName: "plus.app")
                                        .foregroundColor(pages.count < 10 ? .green : .secondary)
                                        .opacity(pages.count < 10 ? 1 : 0.6)
                                }
                                .buttonStyle(.borderless)
                                .disabled(pages.count > 10)
                                
                            }
                            
                            List {
                                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                                    HStack(spacing: 12) {
                                        Image(systemName: "line.3.horizontal")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        
                                        TextField("Page Heading", text: $pages[index].title)
                                            .textFieldStyle(.roundedBorder)
                                            .focused($focusedPageID, equals: page.id)
                                            .onSubmit {
                                                validatePage(at: index)
                                                focusedPageID = nil
                                            }
                                        
                                        Button(action: { deletePage(at: index) }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(pages.count > 1 ? .red : .secondary)
                                                .opacity(pages.count > 1 ? 1 : 0.6)
                                        }
                                        .buttonStyle(.borderless)
                                        .disabled(pages.count <= 1)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .onMove(perform: movePages)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            }
                            .listStyle(.plain)
                            .scrollDisabled(true)
                            .scrollContentBackground(.hidden)
                            .frame(height: max(CGFloat(pages.count) * 52, 52))
                        }
                    }
                    .padding()
                }
                .onAppear(perform: loadPages)
                .onChange(of: pages) { _, newPages in
                    savePages(newPages)
                }
                .onChange(of: focusedPageID) { oldID, newID in
                    if let oldID = oldID, oldID != newID {
                        if let index = pages.firstIndex(where: { $0.id == oldID }) {
                            validatePage(at: index)
                        }
                    }
                }
            } header: {
                Text("Notes Layout")
            } footer: {
                Text("Max 10 pages. When editing the name of a task, click and wait a bit, for some reason the edit state takes longer than usual to update, I'm still looking for a way to fix this.")
            }
        }
    }

    private func validatePage(at index: Int) {
        let trimmed = pages[index].title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            pages[index].title = "Untitled"
        } else {
            pages[index].title = trimmed
        }
    }

    private func addPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pages.append(NotePage(title: "New Page"))
        }
    }

    private func movePages(from source: IndexSet, to destination: Int) {
        pages.move(fromOffsets: source, toOffset: destination)
    }

    private func deletePage(at index: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            _ = pages.remove(at: index)
        }
    }

    private func loadPages() {
        if let decoded = try? JSONDecoder().decode([NotePage].self, from: pagesData), !decoded.isEmpty {
            pages = decoded
        } else {
            pages = [
                NotePage(title: "General"),
                NotePage(title: "Ideas")
            ]
        }
    }

    private func savePages(_ newPages: [NotePage]) {
        if let encoded = try? JSONEncoder().encode(newPages) {
            pagesData = encoded
        }
    }
}
