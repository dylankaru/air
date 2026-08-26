//
//  StreakCard.swift
//  air
//
//  Created by Dylan Karunanayake on 11/8/2026.
//

import SwiftUI
internal import Combine

enum StreakSetting: String, CaseIterable, Identifiable {
    case countUpVis = "Count Up (Remaining units visible)"
    case countUpInvis = "Count Up (Remaining units hidden)"
    case countDown = "Count Down"

    var id: String { rawValue }
}

enum StreakTimeInterval: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case biweekly = "Biweekly"
    case weekly = "Weekly"
    case custom = "Monthly"

    var id: String { rawValue }

    var approximateSeconds: TimeInterval {
        switch self {
        case .daily: return 86_400
        case .weekly: return 86_400 * 7
        case .biweekly: return 86_400 * 14
        case .custom: return 86_400 * 30
        }
    }
}

enum IncrementMode: String, CaseIterable, Identifiable {
    case manual = "Manual (Tap dots directly)"
    case automatic = "Automatic (Time-Based)"
    var id: String { rawValue }
}

struct StreakCard: View {
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("streak_mode") private var currentSettingRaw: String = StreakSetting.countUpVis.rawValue
    @AppStorage("streak_increase_interval") private var timeInterval: StreakTimeInterval = .daily
    @AppStorage("streak_increment_mode") private var incrementMode: IncrementMode = .manual

    @AppStorage("streak_completed_units") private var streakCount: Int = 0
    @AppStorage("streak_goal_unit") private var totalDays: Int = 154

    @AppStorage("streak_primary_colour") private var primaryHex: String = "#3498DB"
    @AppStorage("streak_secondary_colour") private var secondaryHex: String = "#2ECC71"

    @AppStorage("streak_does_goal_have_colour") private var useCustomGoalColor: Bool = false
    @AppStorage("streak_goal_color") private var goalUnitHex: String = "#E74C3C"

    @AppStorage("streak_last_progression") private var lastProgressionTimestamp: Double = 0

    private let dotSize: CGFloat = 12
    private let dotSpacing: CGFloat = 8

    private let ticksPerRow: Int = 4
    private let indicatorRowHeight: CGFloat = 8
    private let indicatorTickSpacing: CGFloat = 5

    @State private var capacity: Int = 132

    private var currentSetting: StreakSetting {
        StreakSetting(rawValue: currentSettingRaw) ?? .countUpVis
    }

    private var cardColors: (primary: Color, secondary: Color) {
        (Color(hex: primaryHex) ?? .blue, Color(hex: secondaryHex) ?? .green)
    }

    private var goalColor: Color {
        Color(hex: goalUnitHex) ?? .red
    }

    let columns = [GridItem(.adaptive(minimum: 12), spacing: 8)]

    var body: some View {
        Card {
            VStack(spacing: 6) {
                IndicatorRow(filled: topTicksFilled)

                GeometryReader { geo in
                    CircleThing()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .onAppear { updateCapacity(for: geo.size) }
                        .onChange(of: geo.size) { _, newSize in updateCapacity(for: newSize) }
                }

                IndicatorRow(filled: bottomTicksFilled)
            }
            .padding(10)
            .contentShape(Rectangle())
            .onTapGesture {
                handleCardTap()
            }
        }
        .onAppear {
            applyAutomaticProgressionIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                applyAutomaticProgressionIfNeeded()
            }
        }
        .onReceive(Timer.publish(every: 3600, on: .main, in: .common).autoconnect()) { _ in
            applyAutomaticProgressionIfNeeded()
        }
    }

    private func handleCardTap() {
        guard incrementMode == .manual else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            streakCount = min(streakCount + 1, totalDays)
        }
    }

    private func toggleUnit(at index: Int) {
        guard incrementMode == .manual else { return }

        let globalIndex = currentLap * capacity + index

        withAnimation(.easeInOut(duration: 0.2)) {
            if globalIndex < streakCount {
                streakCount = globalIndex
            } else {
                streakCount = min(globalIndex + 1, totalDays)
            }
        }
    }

    private func applyAutomaticProgressionIfNeeded() {
        guard incrementMode == .automatic else { return }

        let now = Date()

        if lastProgressionTimestamp == 0 {
            lastProgressionTimestamp = now.timeIntervalSince1970
            return
        }

        let last = Date(timeIntervalSince1970: lastProgressionTimestamp)
        let calendar = Calendar.current
        let elapsedDays = calendar.dateComponents([.day], from: last, to: now).day ?? 0

        let elapsedUnits: Int
        switch timeInterval {
        case .daily:
            elapsedUnits = elapsedDays
        case .weekly:
            elapsedUnits = elapsedDays / 7
        case .biweekly:
            elapsedUnits = elapsedDays / 14
        case .custom:
            elapsedUnits = calendar.dateComponents([.month], from: last, to: now).month ?? 0
        }

        guard elapsedUnits > 0 else { return }

        streakCount = min(streakCount + elapsedUnits, totalDays)
        lastProgressionTimestamp += Double(elapsedUnits) * timeInterval.approximateSeconds
    }

    private func updateCapacity(for size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let perRow = max(1, Int((size.width + dotSpacing) / (dotSize + dotSpacing)))
        let rows = max(1, Int((size.height + dotSpacing) / (dotSize + dotSpacing)))
        let newCapacity = perRow * rows
        if newCapacity != capacity {
            capacity = newCapacity
        }
    }

    private var progressUnits: Int {
        streakCount
    }

    private var currentLap: Int {
        guard capacity > 0 else { return 0 }
        return progressUnits / capacity
    }

    private var positionInLap: Int {
        guard capacity > 0 else { return 0 }
        return progressUnits % capacity
    }

    private var topTicksFilled: Int {
        min(ticksPerRow, currentLap)
    }

    private var bottomTicksFilled: Int {
        min(ticksPerRow, max(0, currentLap - ticksPerRow))
    }

    @ViewBuilder
    private func IndicatorRow(filled: Int) -> some View {
        HStack(spacing: indicatorTickSpacing) {
            ForEach(0..<ticksPerRow, id: \.self) { i in
                Capsule()
                    .fill(i < filled ? cardColors.primary : Color.clear)
                    .frame(height: indicatorRowHeight)
                    .frame(maxWidth: .infinity)
                    .clipShape(Capsule())
            }
        }
        .frame(height: indicatorRowHeight)
    }

    @ViewBuilder
    private func CircleThing() -> some View {
        let goalGlobalIndex = max(0, totalDays - 1)
        let goalLap = capacity > 0 ? goalGlobalIndex / capacity : 0
        let goalPosition = capacity > 0 ? goalGlobalIndex % capacity : 0

        let isGoalIndex = { (index: Int) -> Bool in
            useCustomGoalColor && currentLap == goalLap && index == goalPosition
        }

        switch currentSetting {
        case .countUpVis:
            LazyVGrid(columns: columns, spacing: dotSpacing) {
                ForEach(0..<capacity, id: \.self) { index in
                    Button {
                        toggleUnit(at: index)
                    } label: {
                        Circle()
                            .fill(
                                isGoalIndex(index) ? goalColor :
                                (index < positionInLap ? cardColors.primary : cardColors.secondary)
                            )
                            .frame(width: dotSize, height: dotSize)
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(incrementMode == .manual)
                }
            }

        case .countUpInvis:
            LazyVGrid(columns: columns, spacing: dotSpacing) {
                ForEach(0..<capacity, id: \.self) { index in
                    Button {
                        toggleUnit(at: index)
                    } label: {
                        Circle()
                            .fill(
                                index < positionInLap
                                ? (isGoalIndex(index) ? goalColor : cardColors.primary)
                                : Color.clear
                            )
                            .frame(width: dotSize, height: dotSize)
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(incrementMode == .manual)
                }
            }

        case .countDown:
            LazyVGrid(columns: columns, spacing: dotSpacing) {
                ForEach(0..<capacity, id: \.self) { index in
                    let reversedIndex = capacity - 1 - index
                    Button {
                        toggleUnit(at: reversedIndex)
                    } label: {
                        Circle()
                            .fill(
                                (useCustomGoalColor && currentLap == goalLap && reversedIndex == goalPosition) ? goalColor :
                                (reversedIndex < positionInLap ? cardColors.primary : cardColors.secondary)
                            )
                            .frame(width: dotSize, height: dotSize)
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(incrementMode == .manual)
                }
            }
        }
    }
}
