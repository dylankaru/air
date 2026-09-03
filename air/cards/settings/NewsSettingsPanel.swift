//
//  NewsSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI

struct NewsSettingsView: View {
    @AppStorage("news_user_prefs") private var newsPreference: String = "news today"
    @AppStorage("news_too_distracting") private var turnOffNews: Bool = false
    
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
            
            Section {
                Toggle("Turn News Off", isOn: $turnOffNews)
            } header: {
                Text("News Toggle")
                    .font(.headline)
            } footer: {
                Text("You can disable the news if it's too distracting.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
