//
//  Extensions.swift
//  air
//
//  Created by Dylan Karunanayake on 2/9/2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func conditionalGlassEffect<S: Shape>(in shape: S = Capsule()) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func conditionalGlassButton() -> some View {
        if #available(macOS 26, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.plain)
        }
    }

    func edgePadding(colStart: Int, colEnd: Int, maxColumns: Int = 20, paddingAmount: CGFloat = 16) -> some View {
        self
            .padding(.leading, colStart == 0 ? paddingAmount : 0)
            .padding(.trailing, colEnd == maxColumns ? paddingAmount : 0)
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func gridColumn(_ start: Int, _ end: Int) -> some View {
        layoutValue(key: ColStartKey.self, value: start)
            .layoutValue(key: ColEndKey.self, value: end)
    }
    func gridRow(_ start: Int, _ end: Int) -> some View {
        layoutValue(key: RowStartKey.self, value: start)
            .layoutValue(key: RowEndKey.self, value: end)
    }
}


extension Notification.Name {
    static let clearClipboardCache = Notification.Name("clearClipboardCache")
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data) else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return result
    }
}

extension ButtonStyle where Self == AnimatedButtonStyle {
    static var airButton: AnimatedButtonStyle {
        AnimatedButtonStyle()
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
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }

    func toHex() -> String? {
        let nsColor = NSColor(self)
        guard let srgbColor = nsColor.usingColorSpace(.extendedSRGB)
            ?? nsColor.usingColorSpace(.sRGB)
            ?? nsColor.usingColorSpace(.deviceRGB)
        else { return nil }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        srgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let clampedR = max(0, min(1, Float(r)))
        let clampedG = max(0, min(1, Float(g)))
        let clampedB = max(0, min(1, Float(b)))
        let finalR = clampedR < 0.01 ? 0 : clampedR
        let finalG = clampedG < 0.01 ? 0 : clampedG
        let finalB = clampedB < 0.01 ? 0 : clampedB

        return String(
            format: "#%02X%02X%02X",
            lroundf(finalR * 255),
            lroundf(finalG * 255),
            lroundf(finalB * 255)
        )
    }
}

