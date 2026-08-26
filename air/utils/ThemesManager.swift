//
//  ThemesManager.swift
//  air
//
//  Created by Dylan Karunanayake on 25/8/2026.
//

import SwiftUI

enum Theme: String, Encodable, CaseIterable {
    case light
    case dark
    case green
    case brown
    case blue
    case pink
    
    var backgroundColor: Color {
        switch self {
        case .light: return Color(hex: 0xfffeeb)
        case .dark: return Color(hex: 0x1D1D1D)
        case .green: return Color(hex: 0xD1E6BB)
        case .brown: return Color(hex: 0xD8B686)
        case .blue: return Color(hex: 0x86B2D8)
        case .pink: return Color(hex: 0xFFEAEE)
        }
    }
    
    var widgetColour: Color {
        switch self {
        case .light: return Color(hex: 0xF2E5C9)
        case .dark: return Color(hex: 0x383838)
        case .green: return Color(hex: 0xB1C49D)
        case .brown: return Color(hex: 0xF3DEB0)
        case .blue: return Color(hex: 0xBAD4EB)
        case .pink: return Color(hex: 0xFFFFFF)
        }
    }
    
    var textColour: Color {
        switch self {
        case .light: return Color(hex: 0x1D1D1D)
        case .dark: return Color(hex: 0xD5DDCC)
        case .green: return Color(hex: 0x1D1D1D)
        case .brown: return Color(hex: 0x331D0E)
        case .blue: return Color(hex: 0x0E2B45)
        case .pink: return Color(hex: 0x603F4B)
        }
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
//    
//    static let beige = Color(hex: 0xfffeeb)
////    static let background = ThemesManager.setBackgroundColour()
//    static let widget = Color(hex: 0xF2E5C9)
//    static let middark = Color(hex: 0x1D1D1D)
//    static let test = Color(hex: 0xD4E0D2)
}
