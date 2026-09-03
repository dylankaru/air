//
//  SettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 12/8/2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedTabID: String? = "general"

    var configurableItems: [CardItem] {
        appCards.filter { $0.settingsPanel != nil && $0.title != nil }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTabID) {
                Section {
                    Label("General", systemImage: "gearshape")
                        .tag("general")
                    Label("Layout", systemImage: "rectangle.grid.3x1")
                        .tag("layout")
                }

                Section("Cards") {
                    ForEach(configurableItems) { item in
                        Label(item.title ?? "Card", systemImage: item.icon ?? "square.grid.2x2")
                            .tag(item.id.uuidString)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            if selectedTabID == "general" {
                GeneralSettingsPanel()
            } else if selectedTabID == "layout" {
                CardLayoutSettingsPanel()
            } else if let item = configurableItems.first(where: { $0.id.uuidString == selectedTabID }),
                      let settingsView = item.settingsPanel {
                settingsView
            } else {
                Text("Select a category")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 650, height: 420)
    }
}
