//
//  GeneralSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("air_username") private var userName: String = "Friend"
    @AppStorage("air_autostart") private var autoStart: Bool = true

    @FocusState private var isNameFocused: Bool
    @State private var showNameHint: Bool = false

    var body: some View {
        Form {
            Section("App Behavior") {
                Toggle("Launch at Login", isOn: $autoStart)
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
                            .foregroundStyle(.secondary)
                            .opacity(showNameHint ? 1 : 0)
                    }
                }
                .animation(.easeInOut(duration: 0.8), value: showNameHint)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .onAppear {
            isNameFocused = false
        }
    }
}
