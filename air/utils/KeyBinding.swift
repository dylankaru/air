//
//  KeyBinding.swift
//  air
//
//  Created by Dylan Karunanayake on 22/9/2026.
//

import SwiftUI

struct KeyBinding: Codable, Equatable {
    var key: String
    var modifiers: Int

    var keyEquivalent: KeyEquivalent {
        KeyEquivalent(Character(key))
    }

    var eventModifiers: EventModifiers {
        EventModifiers(rawValue: modifiers)
    }

    static let toggleEditModeDefault = KeyBinding(key: "e", modifiers: EventModifiers.command.rawValue)
}
