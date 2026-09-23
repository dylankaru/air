//
//  ThemeEnvironmentKey.swift
//  air
//
//  Created by Dylan Karunanayake on 23/9/2026.
//


import SwiftUI

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = .light
}

extension EnvironmentValues {
    var activeTheme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}