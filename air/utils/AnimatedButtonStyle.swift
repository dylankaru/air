import SwiftUI

struct AnimatedButtonStyle: ButtonStyle {
    @State private var isHovered = false
    @State private var isLongPressed = false
    @State private var isTapped = false
    @State private var spinAngle: Double = 0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation + spinAngle))
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isTapped)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isLongPressed)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: spinAngle)
            .onHover { isHovered = $0 }
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && !isLongPressed {
                    isTapped = true
                } else if !isPressed && !isLongPressed {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isTapped = false
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                if !pressing && isLongPressed {
                    spinAngle += 425
                    isLongPressed = false
                }
            }, perform: {
                isLongPressed = true
            })
    }

    private var scale: CGFloat {
        if isLongPressed { return 1.2 }
        if isTapped { return 0.85 }
        if isHovered { return 1.15 }
        return 1.0
    }

    private var rotation: Double {
        if isLongPressed { return -65 }
        if isTapped { return 50 }
        if isHovered { return -40 }
        return 0
    }
}
