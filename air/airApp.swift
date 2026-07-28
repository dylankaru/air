//
//  airApp.swift
//  air
//
//  Created by Dylan Karunanayake on 22/7/2026.
//

import SwiftUI
import SwiftData

@main
struct airApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .containerShape(.rect(cornerRadius: 20)) 
                .frame(width: 1400, height: 800)
                .onAppear {
                    if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                        window.center()
                    }
                }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
