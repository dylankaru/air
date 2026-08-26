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
    @Environment(\.openWindow) private var openWindow
    
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
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About air") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "about")
                }
            }
            
            CommandGroup(after: .appInfo) {
                Button("Settings") {
                    openWindow(id: "settings-window")
                }
                Divider()
            }
        }
        
        Window("Settings", id: "settings-window") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        
        Window("About air", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
