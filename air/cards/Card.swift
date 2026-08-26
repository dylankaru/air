//
//  Card.swift
//  air
//
//  Created by Dylan Karunanayake on 24/7/2026.
//

import SwiftUI

struct Card<Content: View>: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    let backgroundColor: Color?
    let content: Content

    init(backgroundColor: Color? = nil, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(backgroundColor ?? theme.widgetColour)
            )
            .clipped()
    }
}
