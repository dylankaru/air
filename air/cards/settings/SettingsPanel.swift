//
//  SettingsPanel.swift
//  air
//
//  Created by Dylan Karunanayake on 2/9/2026.
//

import SwiftUI

struct SettingsPanel<Content: View>: View {
    let name: String
    @ViewBuilder let content: Content
    
    var formattedName: String {
        name.capitalized + " Card"
    }

    var body: some View {
        Form {
            content
        }
        .formStyle(.grouped)
        .navigationTitle(formattedName)
    }
}
