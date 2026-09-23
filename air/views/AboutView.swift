//
//  AboutView.swift
//  air
//
//  Created by Dylan Karunanayake on 25/8/2026.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            
            Text("air")
                .font(.title.bold())
            
            Text("Version 2")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("©2026 Dylan Karunanayake")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(24)
        .frame(width: 260, height: 200)
    }
}
