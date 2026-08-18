//
//  CalendarCard.swift
//  air
//
//  Created by Dylan Karunanayake on 15/8/2026.
//

import SwiftUI
import EventKit

struct CalendarCard: View {
    @State private var eventStore = EKEventStore()
    @State private var isAuthorised = false
    @State private var nextEvent: EKEvent? = nil
    
    var body: some View {
        Card {
            VStack {
                Spacer()
                
                if isAuthorised {
                    if let event = nextEvent {
                        HStack {
                            Spacer()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("NEXT EVENT")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.middark)
                                
                                Text(event.title)
                                    .font(.title2)
                                    .foregroundColor(.middark)
                                    .bold()
                            }
                            .padding()
                            .cornerRadius(12)
                            
                            Spacer()
                            
                            VStack {
                                Text(event.startDate, style: .time)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(event.startDate, style: .date)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.middark)
                                    .font(.subheadline)
                            }
                            .padding()
                            .cornerRadius(12)
                        }
                    } else {
                        Text("No upcoming events found this week.")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Checking calendar access...")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .task {
            await checkAndRequestAccess()
        }
    }
    
    private func checkAndRequestAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        if status == .fullAccess {
            await MainActor.run { isAuthorised = true }
            await fetchNextUpcomingEvent()
        } else if status == .notDetermined {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                if granted {
                    await MainActor.run { isAuthorised = true }
                    await fetchNextUpcomingEvent()
                }
            } catch {
                print("Error requesting calendar access: \(error)")
            }
        }
    }
    
    private func fetchNextUpcomingEvent() async {
        let now = Date()
        guard let oneWeekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return }
        
        let event = await Task.detached {
            let calendars = await eventStore.calendars(for: .event)
            let predicate = await eventStore.predicateForEvents(withStart: now, end: oneWeekFromNow, calendars: calendars)
            let allEvents = await eventStore.events(matching: predicate)
            
            return allEvents
                .filter { $0.startDate > now }
                .sorted { $0.startDate < $1.startDate }
                .first
        }.value
        
        await MainActor.run {
            self.nextEvent = event
        }
    }
}
