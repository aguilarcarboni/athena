import SwiftUI
import HealthKit
import EventKit

struct AggregatorView: View {
    
    @ObservedObject var healthManager: HealthManager = HealthManager.shared
    @ObservedObject var eventManager: EventManager = EventManager.shared
    @State private var isSummaryViewPresented = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        NavigationView {
            List {
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
                Section(header:
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Health Metrics")
                    }
                ) {
                    ForEach(healthManager.todayData, id: \ .type) { healthData in
                        HealthMetricRow(healthData: healthData)
                    }
                }
                
                Section(header:
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.blue)
                        Text("Sleep")
                    }
                ) {
                    ForEach(healthManager.dailySleepData) { sleepEntry in
                        HStack {
                            Text("\(sleepEntry.date, formatter: dateFormatter)")
                            Spacer()
                            Text(String(format: "%.2f hours", sleepEntry.duration / 60))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header:
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.blue)
                        Text("Mindful Session")
                    }
                ) {
                    if let latestMindfulSession = healthManager.latestMindfulSession {
                        HStack {
                            Text("Duration: \(latestMindfulSession.duration) minutes")
                        }
                    } else {
                        EmptyStateRow(message: "No mindful session data")
                    }
                }

                Section(header:
                    HStack {
                        Image(systemName: "figure.run")
                            .foregroundColor(.blue)
                        Text("Workouts")
                    }
                ) {
                    ForEach(healthManager.workouts.suffix(5), id: \ .uuid) { workout in
                        WorkoutRow(workout: workout)
                    }
                }
            }
            .navigationTitle("Daily Overview")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        isSummaryViewPresented = true
                    }) {
                        HStack {
                            Image(systemName: "text.append")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $isSummaryViewPresented) {
                SummaryView()
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

// MARK: - Supporting Views
struct HealthMetricRow: View {
    let healthData: HealthData
    
    var body: some View {
        HStack {
            Image(systemName: healthData.type.icon)
                
            Text(healthData.type.name)
            Spacer()
            Text(String(format: "%.2f", healthData.value))
                .foregroundColor(.secondary)
        }
    }
}


struct WorkoutRow: View {
    let workout: HKWorkout
    
    var body: some View {
        HStack {
            Image(systemName: workout.workoutActivityType.icon)
                .foregroundColor(.blue)

            VStack(alignment: .leading) {
                Text(workout.workoutActivityType.name)
                    .font(.headline)
                Text("Duration: \(formatDuration(workout.duration))")
                    .font(.subheadline)
                Text("Date: \(workout.startDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "N/A"
    }
}
