//
//  TimerSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI

struct TimerSettingsPanel: View {
    @AppStorage("timer_work_duration") private var workDuration: Int = TimerMode.work.defaultDuration
    @AppStorage("timer_rest_duration") private var restDuration: Int = TimerMode.rest.defaultDuration
    @AppStorage("timer_off_duration") private var offDuration: Int = TimerMode.off.defaultDuration
    @AppStorage("timer_use_flashy_timer") private var useFlashyTimer: Bool = true
    
    var body: some View {
        SettingsPanel(name: "Timer") {
            Section("Timer Durations") {
                Stepper("Focus: \(workMinutes.wrappedValue) min", value: workMinutes, in: 1...180)
                Stepper("Break: \(restMinutes.wrappedValue) min", value: restMinutes, in: 1...180)
                Stepper("Rest: \(offMinutes.wrappedValue) min", value: offMinutes, in: 1...180)
            }
            
            Section("Animation") {
                Toggle("Enable Numeric Transition", isOn: $useFlashyTimer)
            }
        }
    }
    
    private var workMinutes: Binding<Int> {
        Binding(
            get: { max(1, workDuration / 60) },
            set: { workDuration = max(1, min(180, $0)) * 60 }
        )
    }
    
    private var restMinutes: Binding<Int> {
        Binding(
            get: { max(1, restDuration / 60) },
            set: { restDuration = max(1, min(180, $0)) * 60 }
        )
    }
    
    private var offMinutes: Binding<Int> {
        Binding(
            get: { max(1, offDuration / 60) },
            set: { offDuration = max(1, min(180, $0)) * 60 }
        )
    }
}
