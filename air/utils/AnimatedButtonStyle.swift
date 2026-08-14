import SwiftUI

struct AnimatedButtonStyle: ButtonStyle {
    @State private var isHovered = false
    @State private var isLongPressed = false
    @State private var spinAngle: Double = 0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(scale(isPressed: configuration.isPressed))
            .rotationEffect(.degrees(rotation(isPressed: configuration.isPressed) + spinAngle))
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.5), value: isLongPressed)
            .animation(.easeInOut(duration: 0.6), value: spinAngle)
            .onHover { isHovered = $0 }
            .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                if !pressing && isLongPressed {
                    // Release after long press: full revolution and reset
                    spinAngle -= 360
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        isLongPressed = false
                        spinAngle = 0
                    }
                }
            }, perform: {
                // Long press triggered: extra -10° (-50° total) and 1.2 scale
                isLongPressed = true
            })
    }

    private func scale(isPressed: Bool) -> CGFloat {
        if isLongPressed { return 1.2 }
        if isPressed { return 0.85 }
        if isHovered { return 1.15 }
        return 1.0
    }

    private func rotation(isPressed: Bool) -> Double {
        if isLongPressed { return -50 }
        if isPressed { return 50 }
        if isHovered { return -40 }
        return 0
    }
}