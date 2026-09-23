//
//  ConversionCard.swift
//  air
//
//

import SwiftUI

enum UnitCategory: String, CaseIterable, Identifiable {
    case length = "Length"
    case mass = "Mass"
    case volume = "Volume"
    case temperature = "Temperature"
    case area = "Area"
    
    var id: Self { self }
    
    var units: [AppUnit] {
        AppUnit.allCases.filter { $0.category == self }
    }
}

enum AppUnit: String, CaseIterable, Identifiable {
    // Length
    case mm = "Millimetres (mm)"
    case cm = "Centimetres (cm)"
    case m = "Metres (m)"
    case km = "Kilometres (km)"
    case inch = "Inches (in)"
    case ft = "Feet (ft)"
    case yd = "Yards (yd)"
    case mi = "Miles (mi)"
    
    // Mass
    case mg = "Milligrams (mg)"
    case g = "Grams (g)"
    case kg = "Kilograms (kg)"
    case oz = "Ounces (oz)"
    case lb = "Pounds (lb)"
    
    // Volume
    case ml = "Millilitres (mL)"
    case l = "Litres (L)"
    case floz = "Fluid Ounces (fl oz)"
    case c = "Cups (c)"
    case pt = "Pints (pt)"
    case gal = "Gallons (gal)"
    
    // Temperature
    case cTemp = "Celsius (°C)"
    case f = "Fahrenheit (°F)"
    case k = "Kelvin (K)"
    
    // Area
    case sqcm = "Square Centimetres (cm²)"
    case sqm = "Square Metres (m²)"
    case ha = "Hectares (ha)"
    case skm = "Square Kilometres (km²)"
    case sqft = "Square Feet (sq ft)"
    case acre = "Acres"
    case sqmi = "Square Miles (sq mi)"
    
    var id: Self { self }
    
    var category: UnitCategory {
        switch self {
        case .mm, .cm, .m, .km, .inch, .ft, .yd, .mi:
            return .length
        case .mg, .g, .kg, .oz, .lb:
            return .mass
        case .ml, .l, .floz, .c, .pt, .gal:
            return .volume
        case .cTemp, .f, .k:
            return .temperature
        case .sqcm, .sqm, .ha, .skm, .sqft, .acre, .sqmi:
            return .area
        }
    }
    
    var foundationUnit: Dimension {
        switch self {
        case .mm: return UnitLength.millimeters
        case .cm: return UnitLength.centimeters
        case .m: return UnitLength.meters
        case .km: return UnitLength.kilometers
        case .inch: return UnitLength.inches
        case .ft: return UnitLength.feet
        case .yd: return UnitLength.yards
        case .mi: return UnitLength.miles
            
        case .mg: return UnitMass.milligrams
        case .g: return UnitMass.grams
        case .kg: return UnitMass.kilograms
        case .oz: return UnitMass.ounces
        case .lb: return UnitMass.pounds
            
        case .ml: return UnitVolume.milliliters
        case .l: return UnitVolume.liters
        case .floz: return UnitVolume.fluidOunces
        case .c: return UnitVolume.cups
        case .pt: return UnitVolume.pints
        case .gal: return UnitVolume.gallons
            
        case .cTemp: return UnitTemperature.celsius
        case .f: return UnitTemperature.fahrenheit
        case .k: return UnitTemperature.kelvin
            
        case .sqcm: return UnitArea.squareCentimeters
        case .sqm: return UnitArea.squareMeters
        case .ha: return UnitArea.hectares
        case .skm: return UnitArea.squareKilometers
        case .sqft: return UnitArea.squareFeet
        case .acre: return UnitArea.acres
        case .sqmi: return UnitArea.squareMiles
        }
    }
}

struct ConversionCard: View {
    @Environment(\.activeTheme) private var theme
    
    @State private var fromUnit: AppUnit = .m
    @State private var toUnit: AppUnit = .km
    @State private var inputValue: Double = 1.0
    
    @State private var fromSearchText: String = ""
    @State private var toSearchText: String = ""
    
    var compatibleUnits: [AppUnit] {
        AppUnit.allCases.filter { $0.category == fromUnit.category }
    }
    
    var convertedValue: Double {
        guard fromUnit.category == toUnit.category else { return 0.0 }
        let inputMeasurement = Measurement(value: inputValue, unit: fromUnit.foundationUnit)
        return inputMeasurement.converted(to: toUnit.foundationUnit).value
    }
    
    var body: some View {
        Card {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FROM")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    TextField("Value", value: $inputValue, format: .number)
                        .font(.title2)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .textFieldStyle(.plain)
                    
                    Divider()
                    
                    Picker("From Unit", selection: $fromUnit) {
                        ForEach(UnitCategory.allCases) { category in
                            Section(category.rawValue) {
                                ForEach(category.units) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(.white)
                    .onChange(of: fromUnit) { _, newFromUnit in
                        if toUnit.category != newFromUnit.category || toUnit == newFromUnit {
                            toUnit = compatibleUnits.first(where: { $0 != newFromUnit }) ?? newFromUnit
                        }
                    }
                }
                .padding(12)
                .background(theme.textColour.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                
                Button(action: swapUnits) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                        .padding(8)
                        .background(theme.textColour.opacity(0.7), in: Circle())
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("TO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text(convertedValue, format: .number.precision(.fractionLength(0...4)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    Picker("To Unit", selection: $toUnit) {
                        ForEach(compatibleUnits) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(.white)
                }
                .padding(12)
                .background(theme.textColour.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(10)
        }
    }
    
    private func swapUnits() {
        let temp = fromUnit
        fromUnit = toUnit
        toUnit = temp
    }
    
    private func autoSelectFromUnit(matching query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        
        if let match = AppUnit.allCases.first(where: {
            $0.rawValue.lowercased().contains(trimmed) || String(describing: $0).lowercased() == trimmed
        }) {
            fromUnit = match
        }
    }
    
    private func autoSelectToUnit(matching query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        
        if let match = compatibleUnits.first(where: {
            $0.rawValue.lowercased().contains(trimmed) || String(describing: $0).lowercased() == trimmed
        }) {
            toUnit = match
        }
    }
}
