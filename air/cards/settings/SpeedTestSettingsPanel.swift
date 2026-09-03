//
//  SpeedTestSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI

struct SpeedTestSettingsView: View {
    @AppStorage("speed_test_do") private var doSpeedTest: Bool = true
    
    var body: some View {
        SettingsPanel(name: "Speed Test") {
            Section("Speed Test Toggle") {
                Toggle("Do Speed Test", isOn: $doSpeedTest)
            }
        }
    }
}
