//
//  RNGCard.swift
//  air
//
//  Created by Dylan Karunanayake on 10/9/2026.
//

import SwiftUI

let rngLastUsedFilename = "rng_last_used.json"

struct RangeModel: Codable {
    var min: Int
    var max: Int
}

struct RNGCard: View {
    @Environment(\.activeTheme) private var theme
    
    @State private var min: Int = 0
    @State private var max: Int = 10
    @State private var result: Int? = nil
    
    private var isValidRange: Bool { min <= max }
    
    var body: some View {
        Card {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Min")
                            .font(.caption)
                            .foregroundColor(theme.textColour)
                        TextField("Min", value: $min, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Max")
                            .font(.caption)
                            .foregroundColor(theme.textColour)
                        TextField("Max", value: $max, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                if !isValidRange {
                    Text("Min must be less than or equal to \(max)")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text(result.map(String.init) ?? "—")
                        .font(.custom("ClashDisplayVariable-Bold", size: 40))
                        .foregroundColor(theme.textColour)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .padding()
        }
        .onAppear {
            load()
            generate()
        }
        .onChange(of: min) { _, _ in
            save()
            generate()
        }
        .onChange(of: max) { _, _ in
            save()
            generate()
        }
    }
    
    private func generate() {
        guard isValidRange else { return }
        result = Int.random(in: min...max)
    }
    
    private func save() {
        let rangeData = RangeModel(min: min, max: max)
        
        try? JSONManager.save(rangeData, to: rngLastUsedFilename)
    }
    
    private func load() {
        if let loadedRange = JSONManager.load(RangeModel.self, from: rngLastUsedFilename) {
            min = loadedRange.min
            max = loadedRange.max
        }
    }
}
