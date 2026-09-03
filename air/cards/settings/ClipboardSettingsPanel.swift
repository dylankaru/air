//
//  ClipboardSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 22/8/2026.
//

import SwiftUI

struct ClipboardSettingsPanel: View {
    @State private var showClearCacheDialog: Bool = false
    
    var body: some View {
        SettingsPanel(name: "Clipboard") {
            Section("Clipboard Cache") {
                Button ("Clear Clipboard Cache", role: .destructive)
                {
                    showClearCacheDialog = true
                }
                .confirmationDialog(
                    "Are you sure you want to clear your clipboard history?",
                    isPresented: $showClearCacheDialog,
                    titleVisibility: .visible
                ) {
                    Button("Yes", role: .destructive) {
                        ClipboardStorage.clear()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("It will be permanently deleted.")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
