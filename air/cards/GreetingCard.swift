//
//  GreetingCard.swift
//  air
//
//  Created by Dylan Karunanayake on 24/7/2026.
//

import SwiftUI
import AppKit

struct GreetingCard: View {
    @AppStorage("air_username") private var userName: String = "Friend"
    @State private var greetingText: String = ""
    @State private var isLoading: Bool = true
    @State private var dynamicSubtitle: String = ""

    private var currentLocalTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }

    let morningList  = ["Ready to make today count?", "What's your big plan chief?", "What a day to be alive...", "Go get 'em tiger!"]
    let arvoList     = ["Hope your day is going well", "We in high gear yet?", "Look at you, what a productivity diva!", "Get back to work bro."]
    let eveningList  = ["Time to wind down.", "You rocked today!", "It's getting dark.", "Wrap it up, sleep's important too you know..."]
    let midnightList = ["Burning the midnight oil?", "What kept you up tonight?", "It's a bit... too dark out, right?", "Boi go to sleep."]

    var body: some View {
        Card(backgroundColor: .clear) {
            GeometryReader { geo in
                if isLoading {
                    ProgressView()
                } else if !greetingText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greetingText)
                            .font(.custom("ClashDisplayVariable-Bold", size: 55))
                            .lineLimit(1)
                            .minimumScaleFactor(0.2)
                            .allowsTightening(true)
                            .foregroundColor(.middark)
                        
                        Text(dynamicSubtitle)
                            .font(.system(size: 14, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(Color.middark)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    Text("No greeting available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .task {
            await loadGreeting()
        }
    }

    private func loadGreeting() async {
        isLoading = true
        defer { isLoading = false }

        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: dynamicSubtitle = morningList.randomElement() ?? "Good morning!"
        case 12..<17: dynamicSubtitle = arvoList.randomElement() ?? "Good afternoon!"
        case 17..<22: dynamicSubtitle = eveningList.randomElement() ?? "Good evening!"
        default: dynamicSubtitle = midnightList.randomElement() ?? "It's very, very late."
        }

        let timeOfDay = currentLocalTime

        do {
            let result = try await fetchGreeting(userName: userName, timeOfDay: timeOfDay)
            greetingText = result.greeting
        } catch {
            greetingText = "Welcome back, \(userName)"
        }
    }
}
