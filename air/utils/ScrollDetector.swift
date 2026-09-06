//
//  ScrollDetector.swift
//  air
//
//  Created by Dylan Karunanayake on 5/9/2026.
//

import SwiftUI

struct ScrollDetector: NSViewRepresentable {
    var onSwipe: (Int) -> Void
    
    func makeNSView(context: Context) -> WheelTracker {
        let view = WheelTracker()
        view.onSwipe = onSwipe
        return view
    }
    
    func updateNSView(_ nsView: WheelTracker, context: Context) {}
    
    class WheelTracker: NSView {
        var onSwipe: ((Int) -> Void)?
        
        private var gestureActive = false
        private var hasTriggeredInCurrentGesture = false
        
        private var lastMouseScrollTime = Date.distantPast
        private let mouseDebounceInterval: TimeInterval = 0.3
        private let threshold: CGFloat = 6.0
        
        override func scrollWheel(with event: NSEvent) {
            let isTrackpad = !event.phase.isEmpty || !event.momentumPhase.isEmpty
            
            if isTrackpad {
                handleTrackpad(event)
            } else {
                let now = Date()
                guard now.timeIntervalSince(lastMouseScrollTime) > mouseDebounceInterval else { return }
                lastMouseScrollTime = now
                evaluateAndTrigger(dx: event.scrollingDeltaX, dy: event.scrollingDeltaY)
            }
        }
        
        private func handleTrackpad(_ event: NSEvent) {
            if event.phase.contains(.began) {
                gestureActive = true
                hasTriggeredInCurrentGesture = false
            }
            
            let isEnding = event.phase.contains(.ended) || event.phase.contains(.cancelled) || event.momentumPhase.contains(.ended) || event.momentumPhase.contains(.cancelled)
            
            if isEnding {
                gestureActive = false
                hasTriggeredInCurrentGesture = false
                return
            }
            
            guard gestureActive, !hasTriggeredInCurrentGesture else { return }
            evaluateAndTrigger(dx: event.scrollingDeltaX, dy: event.scrollingDeltaY)
        }
        
        private func evaluateAndTrigger(dx: CGFloat, dy: CGFloat) {
            if abs(dx) > abs(dy) {
                guard abs(dx) > threshold else { return }
                trigger(dx > 0 ? -1 : 1)
            } else {
                guard abs(dy) > threshold else { return }
                trigger(dy > 0 ? -1 : 1)
            }
        }
        
        private func trigger(_ steps: Int) {
            hasTriggeredInCurrentGesture = true
            DispatchQueue.main.async {
                self.onSwipe?(steps)
            }
        }
    }
}
