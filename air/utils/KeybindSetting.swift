//
//  KeybindSetting.swift
//  air
//
//  Created by Dylan Karunanayake on 22/9/2026.
//


import SwiftUI

struct KeybindSetting: View {
    @State private var shortcutError: String?
    
    let label: String
    let actionKey: String
    let defaultBinding: KeyBinding
    
    @ObservedObject private var layoutStore = CardLayoutStore.shared
    
    @State private var isRecordingShortcut = false

    var body: some View {
        let current = layoutStore.shortcut(for: actionKey, default: defaultBinding)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()

                            Button(isRecordingShortcut ? "Press a key…" : current.displayString) {
                    shortcutError = nil
                    isRecordingShortcut = true
                }
                .buttonStyle(.bordered)
                .background(
                    KeyRecorderView(
                        isRecording: $isRecordingShortcut,
                        onCapture: { newBinding in
                            layoutStore.setShortcut(newBinding, for: actionKey)
                            shortcutError = nil
                            isRecordingShortcut = false
                        },
                        onInvalid: { message in
                            shortcutError = message
                            // stay in recording mode so they can immediately retry
                        }
                    )
                    .frame(width: 0, height: 0)
                )

                if current != defaultBinding {
                    Button {
                        layoutStore.resetShortcut(for: actionKey)
                        shortcutError = nil
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)
                }
            }

            if let shortcutError {
                Text(shortcutError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}
