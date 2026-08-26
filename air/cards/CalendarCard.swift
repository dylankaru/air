//
//  CalendarCard.swift
//  air
//
//  Created by Dylan Karunanayake on 15/8/2026.
//

import SwiftUI
import EventKit

struct CalendarCard: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    @State private var eventStore = EKEventStore()
    @State private var isAuthorised = false
    @State private var upcomingEvents: [EKEvent] = []

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 4) {
                Text("UPCOMING")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textColour)

                if isAuthorised {
                    if !upcomingEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(upcomingEvents, id: \.eventIdentifier) { event in
                                eventRow(for: event)

                                if event.eventIdentifier != upcomingEvents.last?.eventIdentifier {
                                    Divider()
                                }
                            }
                        }
                    } else {
                        Text("No upcoming events found this week.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                } else {
                    Text("Checking calendar access...")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding()
        }
        .task {
            await checkAndRequestAccess()
        }
    }

    @ViewBuilder
    private func eventRow(for event: EKEvent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 8, height: 8)

                    Text(event.title)
                        .font(.title3)
                        .foregroundColor(theme.textColour)
                        .bold()
                        .lineLimit(1)
                }

                Spacer()

                Text(relativeDayLabel(for: event.startDate))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textColour)

                if event.isAllDay {
                    Text("All day")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                } else {
                    Text(event.startDate, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                if event.hasAlarms {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                        .foregroundColor(theme.textColour)
                }
            }

            HStack(spacing: 12) {
                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(theme.textColour)
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(theme.textColour)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(theme.textColour)
                    Text(durationText(for: event))
                        .font(.subheadline)
                        .foregroundColor(theme.textColour)
                }

                Spacer()

                Text(event.startDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(theme.textColour)
            }

            if let notes = event.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .foregroundColor(theme.textColour)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func relativeDayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInTomorrow(date) {
            return "TOMORROW"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date).uppercased()
        }
    }

    private func durationText(for event: EKEvent) -> String {
        if event.isAllDay {
            return "All day"
        }

        let minutes = Int(event.endDate.timeIntervalSince(event.startDate) / 60)

        if minutes < 60 {
            return "\(minutes) min"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if remainingMinutes == 0 {
            return "\(hours) hr"
        } else {
            return "\(hours) hr \(remainingMinutes) min"
        }
    }

    private func checkAndRequestAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)

        if status == .fullAccess {
            await MainActor.run { isAuthorised = true }
            await fetchUpcomingEvents()
        } else if status == .notDetermined {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                if granted {
                    await MainActor.run { isAuthorised = true }
                    await fetchUpcomingEvents()
                }
            } catch {
                print("Error requesting calendar access: \(error)")
            }
        }
    }

    private func fetchUpcomingEvents() async {
        let now = Date()
        guard let oneWeekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return }

        let events = await Task.detached {
            let calendars = await eventStore.calendars(for: .event)
            let predicate = await eventStore.predicateForEvents(withStart: now, end: oneWeekFromNow, calendars: calendars)
            let allEvents = await eventStore.events(matching: predicate)

            var seen = Set<String>()
            let deduped = allEvents
                .filter { $0.startDate > now }
                .sorted { $0.startDate < $1.startDate }
                .filter { event in
                    let key = event.calendarItemExternalIdentifier
                        ?? "\(event.title ?? "")|\(event.startDate.timeIntervalSince1970)|\(event.endDate.timeIntervalSince1970)"
                    if seen.contains(key) {
                        return false
                    }
                    seen.insert(key)
                    return true
                }

            return Array(deduped.prefix(3))
        }.value

        await MainActor.run {
            self.upcomingEvents = events
        }
    }
}
