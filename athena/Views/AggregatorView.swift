import SwiftUI
import HealthKit
import EventKit

struct AggregatorView: View {
    @ObservedObject var healthManager: HealthManager
    @ObservedObject var eventManager: EventManager
    @ObservedObject var sharedDataManager: SharedDataManager
    
    @State private var isAthenaViewPresented = false

    init(healthManager: HealthManager, eventManager: EventManager, sharedDataManager: SharedDataManager) {
        self.healthManager = healthManager
        self.eventManager = eventManager
        self.sharedDataManager = sharedDataManager
    }
    
    var body: some View {
        NavigationView {
            List {
                if let aiData = sharedDataManager.aiData {
                    Section(header: 
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Health Metrics")
                        }
                    ) {
                        HealthMetricRow(icon: "figure.walk", title: "Steps", value: "\(Int(aiData.healthData.steps))")
                        HealthMetricRow(icon: "figure.walk.motion", title: "Distance", value: "\(String(format: "%.1f", aiData.healthData.distanceWalkingRunning / 1000)) km")
                        HealthMetricRow(icon: "stairs", title: "Flights", value: "\(Int(aiData.healthData.flightsClimbed))")
                        HealthMetricRow(icon: "heart.circle.fill", title: "Heart Rate", value: "\(Int(aiData.healthData.heartRate)) BPM")
                        HealthMetricRow(icon: "bed.double.fill", title: "Sleep", value: "\(String(format: "%.1f", aiData.healthData.sleepHours)) hrs")
                        HealthMetricRow(icon: "flame.fill", title: "Total Energy", value: "\(Int(aiData.healthData.activeEnergyBurned + aiData.healthData.basalEnergyBurned)) kcal")
                        HealthMetricRow(icon: "lungs.fill", title: "Respiratory", value: "\(Int(aiData.healthData.respiratoryRate)) /min")
                        HealthMetricRow(icon: "heart.fill", title: "Resting HR", value: "\(Int(aiData.healthData.restingHeartRate)) BPM")
                    }

                    // Yesterday's Reminders Section
                    Section(header: 
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                            Text("Yesterday's Reminders")
                        }
                    ) {
                        if aiData.calendarData.yesterdayReminders.isEmpty {
                            EmptyStateRow(message: "No reminders yesterday")
                        } else {
                            ForEach(aiData.calendarData.yesterdayReminders, id: \.title) { reminder in
                                ReminderRow(reminder: reminder)
                            }
                        }
                    }
                    
                    // Yesterday's Events Section
                    Section(header: 
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.purple)
                            Text("Yesterday's Events")
                        }
                    ) {
                        if aiData.calendarData.yesterdayEvents.isEmpty {
                            EmptyStateRow(message: "No events yesterday")
                        } else {
                            ForEach(aiData.calendarData.yesterdayEvents, id: \.title) { event in
                                EventRow(event: event)
                            }
                        }
                    }
                    
                    // Today's Events Section
                    Section(header: 
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("Today's Events")
                        }
                    ) {
                        if aiData.calendarData.todayEvents.isEmpty {
                            EmptyStateRow(message: "No events today")
                        } else {
                            ForEach(aiData.calendarData.todayEvents, id: \.title) { event in
                                EventRow(event: event)
                            }
                        }
                    }
                    
                    // Today's Reminders Section
                    Section(header: 
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.green)
                            Text("Today's Reminders")
                        }
                    ) {
                        if aiData.calendarData.todayReminders.isEmpty {
                            EmptyStateRow(message: "No reminders today")
                        } else {
                            ForEach(aiData.calendarData.todayReminders, id: \.title) { reminder in
                                ReminderRow(reminder: reminder)
                            }
                        }
                    }
                    
                    // Tomorrow's Reminders Section
                    Section(header:
                        HStack {
                            Image(systemName: "bell.badge.waveform")
                                .foregroundColor(.blue)
                            Text("Tomorrow's Reminders")
                        }
                    ) {
                        if aiData.calendarData.tomorrowReminders.isEmpty {
                            EmptyStateRow(message: "No reminders for tomorrow")
                        } else {
                            ForEach(aiData.calendarData.tomorrowReminders, id: \.title) { reminder in
                                ReminderRow(reminder: reminder)
                            }
                        }
                    }

                    // Tomorrow's Events Section
                    Section(header: 
                        HStack {
                            Image(systemName: "calendar.badge.forward")
                                .foregroundColor(.cyan)
                            Text("Tomorrow's Events")
                        }
                    ) {
                        if aiData.calendarData.tomorrowEvents.isEmpty {
                            EmptyStateRow(message: "No events tomorrow")
                        } else {
                            ForEach(aiData.calendarData.tomorrowEvents, id: \.title) { event in
                                EventRow(event: event)
                            }
                        }
                    }

                } else {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Text("Loading data...")
                                .foregroundColor(.gray)
                            Spacer()
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
                    .disabled(sharedDataManager.aiData == nil)
                }
            }
            .onAppear {
                healthManager.requestAuthorization()
                eventManager.requestAuthorization()
            }
            .sheet(isPresented: $isAthenaViewPresented) {
                SummaryView(aiData: sharedDataManager.aiData)
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
    let event: AIDataModel.EventItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.blue)
                Text(event.title)
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
    let reminder: AIDataModel.ReminderItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(reminder.isCompleted ? .green : .gray)
                Text(reminder.title)
                    .font(.headline)
                if reminder.priority > 0 {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            if let dueDate = reminder.dueDate {
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
