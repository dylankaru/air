//
//  KeyRecorderView.swift
//  air
//
//  Created by Dylan Karunanayake on 23/9/2026.
//

import SwiftUI

struct KeyRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onCapture: (KeyBinding) -> Void
    var onInvalid: ((String) -> Void)? = nil

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onKeyDown = { event in
            guard let chars = event.charactersIgnoringModifiers,
                  let char = chars.lowercased().first else { return }

            let modifiers = EventModifiers(event.modifierFlags)
            let binding = KeyBinding(key: String(char), modifiers: modifiers.rawValue)

            // Require at least one modifier key
            guard !modifiers.isEmpty else {
                onInvalid?("Must include a modifier key (⌘/⌥/⌃/⇧)")
                return
            }

            // Disallow the reserved search shortcut
            let reservedSearch = KeyBinding(key: "k", modifiers: EventModifiers.command.rawValue)
            guard binding != reservedSearch else {
                onInvalid?("⌘K is reserved for Search")
                return
            }

            onCapture(binding)
        }
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        DispatchQueue.main.async {
            if isRecording {
                nsView.window?.makeFirstResponder(nsView)
            } else if nsView.window?.firstResponder === nsView {
                nsView.window?.makeFirstResponder(nil)
            }
        }
    }
}

final class RecorderNSView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }
}
