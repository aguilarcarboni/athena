import SwiftUI
import HealthKit
import EventKit

struct AggregatorView: View {
    @ObservedObject var healthManager: HealthManager = HealthManager()
    @ObservedObject var eventManager: EventManager = EventManager()
    
    @State private var isAthenaViewPresented = false

    var body: some View {
        NavigationView {
            List {
                // Health Metrics Section
                Section(header: 
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Health Metrics")
                    }
                ) {
                    HealthMetricRow(icon: "figure.walk", title: "Steps", value: "\(Int(healthManager.steps))")
                    HealthMetricRow(icon: "figure.walk.motion", title: "Distance", value: "\(String(format: "%.1f", healthManager.distanceWalkingRunning / 1000)) km")
                    HealthMetricRow(icon: "stairs", title: "Flights", value: "\(Int(healthManager.flightsClimbed))")
                    HealthMetricRow(icon: "heart.circle.fill", title: "Heart Rate", value: "\(Int(healthManager.heartRate)) BPM")
                    HealthMetricRow(icon: "bed.double.fill", title: "Sleep", value: "\(String(format: "%.1f", healthManager.sleepHours)) hrs")
                    HealthMetricRow(icon: "flame.fill", title: "Total Energy", value: "\(Int(healthManager.activeEnergyBurned + healthManager.basalEnergyBurned)) kcal")
                    HealthMetricRow(icon: "lungs.fill", title: "Respiratory", value: "\(Int(healthManager.respiratoryRate)) /min")
                    HealthMetricRow(icon: "heart.fill", title: "Resting HR", value: "\(Int(healthManager.restingHeartRate)) BPM")
                }

                Section(header: 
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Yesterday's Events")
                    }
                ) {
                    let calendar = Calendar.current
                    let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!
                    let yesterdayEvents = eventManager.events.filter { calendar.isDate($0.event.startDate, inSameDayAs: yesterday) }
                    if yesterdayEvents.isEmpty {
                        EmptyStateRow(message: "No events yesterday")
                    } else {
                        ForEach(yesterdayEvents, id: \ .id) { eventItem in
                            EventRow(event: eventItem.event)
                        }
                    }
                }
                Section(header: 
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.green)
                        Text("Yesterday's Reminders")
                    }
                ) {
                    let calendar = Calendar.current
                    let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!
                    let yesterdayReminders = eventManager.reminders.filter { $0.dueDateComponents?.date != nil && calendar.isDate($0.dueDateComponents!.date!, inSameDayAs: yesterday) }
                    if yesterdayReminders.isEmpty {
                        EmptyStateRow(message: "No reminders yesterday")
                    } else {
                        ForEach(yesterdayReminders, id: \ .calendarItemIdentifier) { reminder in
                            ReminderRow(reminder: reminder)
                        }
                    }
                }

                Section(header: 
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Today's Events")
                    }
                ) {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let todayEvents = eventManager.events.filter { calendar.isDate($0.event.startDate, inSameDayAs: today) }
                    if todayEvents.isEmpty {
                        EmptyStateRow(message: "No events today")
                    } else {
                        ForEach(todayEvents, id: \ .id) { eventItem in
                            EventRow(event: eventItem.event)
                        }
                    }
                }
                Section(header: 
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.green)
                        Text("Today's Reminders")
                    }
                ) {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let todayReminders = eventManager.reminders.filter { $0.dueDateComponents?.date != nil && calendar.isDate($0.dueDateComponents!.date!, inSameDayAs: today) }
                    if todayReminders.isEmpty {
                        EmptyStateRow(message: "No reminders today")
                    } else {
                        ForEach(todayReminders, id: \ .calendarItemIdentifier) { reminder in
                            ReminderRow(reminder: reminder)
                        }
                    }
                }

                Section(header: 
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Tomorrow's Events")
                    }
                ) {
                    let calendar = Calendar.current
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
                    let tomorrowEvents = eventManager.events.filter { calendar.isDate($0.event.startDate, inSameDayAs: tomorrow) }
                    if tomorrowEvents.isEmpty {
                        EmptyStateRow(message: "No events tomorrow")
                    } else {
                        ForEach(tomorrowEvents, id: \ .id) { eventItem in   
                            EventRow(event: eventItem.event)
                        }
                    }
                }
                Section(header: 
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.green)
                        Text("Tomorrow's Reminders")
                    }
                ) {
                    let calendar = Calendar.current
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
                    let tomorrowReminders = eventManager.reminders.filter { $0.dueDateComponents?.date != nil && calendar.isDate($0.dueDateComponents!.date!, inSameDayAs: tomorrow) }
                    if tomorrowReminders.isEmpty {
                        EmptyStateRow(message: "No reminders tomorrow")
                    } else {
                        ForEach(tomorrowReminders, id: \ .calendarItemIdentifier) { reminder in
                            ReminderRow(reminder: reminder)
                        }
                    }
                }
            }
            .navigationTitle("Daily Overview")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        isAthenaViewPresented = true
                    }) {
                        HStack {
                            Image(systemName: "text.append")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .onAppear {
                healthManager.requestAuthorization()
                eventManager.requestAuthorization()
            }
            .sheet(isPresented: $isAthenaViewPresented) {
                SummaryView(healthManager: healthManager, events: eventManager.events.map { $0.event }, reminders: eventManager.reminders)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct HealthMetricRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.blue)
                Text(event.title ?? "(No Title)")
                    .font(.headline)
            }
            Text(formatDate(event.startDate))
                .font(.subheadline)
                .foregroundColor(.gray)
            if let location = event.location {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    Text(location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ReminderRow: View {
    let reminder: EKReminder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(reminder.isCompleted ? .green : .gray)
                Text(reminder.title ?? "(No Title)")
                    .font(.headline)
                if reminder.priority > 0 {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            if let dueDate = reminder.dueDateComponents?.date {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text(formatDate(dueDate))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            if let notes = reminder.notes {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.gray)
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EmptyStateRow: View {
    let message: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(message)
                .foregroundColor(.gray)
                .italic()
            Spacer()
        }
    }
}
