//
//  NewsSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI

struct NewsSettingsPanel: View {
    @AppStorage("news_user_prefs") private var newsPreference: String = "news today"
    
    var body: some View {
        SettingsPanel(name: "News") {
            Section {
                TextField("e.g. Technology, Australia, NBA", text: $newsPreference)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("News Topics")
                    .font(.headline)
            } footer: {
                Text("The news feed will fetch articles based on the embedded search term. If you wish region specifc, inject it here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
