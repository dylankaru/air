//
//  SettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 12/8/2026.
//

import SwiftUI
import AppKit

extension Color {
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

struct SettingsView: View {
    @State private var selectedTabID: String? = "general"

    var configurableItems: [CardItem] {
        appCards.filter { $0.settingsView != nil && $0.title != nil }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTabID) {
                Section {
                    Label("General", systemImage: "gearshape")
                        .tag("general")
                }

                Section("Cards") {
                    ForEach(configurableItems) { item in
                        Label(item.title ?? "Card", systemImage: item.icon ?? "square.grid.2x2")
                            .tag(item.id.uuidString)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            if selectedTabID == "general" {
                GeneralSettingsView()
            } else if let item = configurableItems.first(where: { $0.id.uuidString == selectedTabID }),
                      let settingsView = item.settingsView {
                settingsView
            } else {
                Text("Select a category")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 650, height: 420)
    }
}
