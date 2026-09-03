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
    case velvet
    
    var backgroundColor: Color {
        switch self {
        case .light: return Color(hex: 0xfffeeb)
        case .dark: return Color(hex: 0x1D1D1D)
        case .green: return Color(hex: 0xD1E6BB)
        case .brown: return Color(hex: 0xD8B686)
        case .blue: return Color(hex: 0x86B2D8)
        case .pink: return Color(hex: 0xFFEAEE)
        case .velvet: return Color(hex: 0x9C2E2C)
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
        case .velvet: return Color(hex: 0xBA4F4E)
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
        case .velvet: return Color(hex: 0xD5DDCC)
        }
    }
    
    var textVariety: TextVariety {
        switch self {
        case .light: return TextVariety.dark
        case .dark: return TextVariety.light
        case .green: return TextVariety.dark
        case .brown: return TextVariety.dark
        case .blue: return TextVariety.dark
        case .pink: return TextVariety.dark
        case .velvet: return TextVariety.light
        }
    }
}

enum TextVariety: String, Codable, CaseIterable {
    case dark
    case light
}
