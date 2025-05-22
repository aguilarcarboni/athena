import SwiftUI
import HealthKit
import EventKit

struct FitnessView: View {
    
    @ObservedObject var healthManager: HealthManager = HealthManager.shared
    @ObservedObject var eventManager: EventManager = EventManager.shared
    @State private var isSummaryViewPresented = false

    var body: some View {
        NavigationView {
            List {
                Section(header: 
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Health Metrics")
                    }
                ) {
                    ForEach(healthManager.data, id: \ .type) { healthData in
                        HealthMetricRow(icon: "heart.fill", title: healthData.type.description, value: String(format: "%.2f", healthData.value))
                    }
                }
                Section(header: 
                    HStack {
                        Image(systemName: "figure.run")
                            .foregroundColor(.blue)
                        Text("Workouts")
                    }
                ) {
                    ForEach(healthManager.workouts.suffix(3), id: \ .uuid) { workout in
                        WorkoutRow(workout: workout)
                    }
                }
            }
            .navigationTitle("Fitness Overview")
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
                SummaryView(summaryType: .workout)
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
