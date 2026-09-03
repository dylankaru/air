//
//  GeneralSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI
import ServiceManagement

struct GeneralSettingsPanel: View {
    @AppStorage("air_username") private var userName: String = "Friend"
    @AppStorage("air_theme") private var theme: Theme = .light
    @AppStorage("air_boot_on_start") private var autoStart: Bool = SMAppService.mainApp.status == .enabled
    @AppStorage("air_two_settings_buttons") private var twoButtons: Bool = false
    
    @FocusState private var isNameFocused: Bool
    @State private var showNameHint: Bool = false

    var body: some View {
        SettingsPanel(name: "General") {
            Section("App Behavior") {
                Toggle("Launch at Login", isOn: $autoStart)
                    .onChange(of: autoStart) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update launch at login: \(error.localizedDescription)")
                        }
                    }
                
                Picker("Theme", selection: $theme) {
                    ForEach(Theme.allCases, id: \.self) { themeOption in
                        Text(themeOption.rawValue.capitalized).tag(themeOption)
                    }
                }
                .pickerStyle(.menu)
                
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Two Settings Buttons", isOn: $twoButtons)
                    
                    Text("Adds a secondary settings shortcut in the bottom right of the screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("User Details") {
                VStack {
                    TextField("Enter username", text: $userName, prompt: Text("LeBron James"))
                        .textFieldStyle(.roundedBorder)
                        .focused($isNameFocused)
                        .onChange(of: userName) { _, _ in
                            showNameHint = true
                        }

                    if showNameHint {
                        Text("Your name will update upon restarting the app")
                            .font(.system(size: 8).monospaced())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 6)
                            .foregroundColor(.secondary)
                            .opacity(showNameHint ? 1 : 0)
                    }
                }
                .animation(.easeInOut(duration: 0.8), value: showNameHint)
            }
        }
        .onAppear {
            isNameFocused = false
            autoStart = SMAppService.mainApp.status == .enabled
        }
    }
}
