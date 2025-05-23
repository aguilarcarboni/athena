import SwiftUI

struct ContentView: View {
    
    @ObservedObject var healthManager: HealthManager = HealthManager.shared
    @ObservedObject var eventManager: EventManager = EventManager.shared
    @ObservedObject var notificationManager: NotificationManager = NotificationManager.shared
    @State var isLoading: Bool = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                AggregatorView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Aggregator")
                    }
            }
        }
        .onAppear {
            healthManager.requestAuthorization()
            eventManager.requestAuthorization()
            healthManager.fetchHealthDataFromLast24Hours()
            healthManager.fetchWorkouts()
            Task {
                _ = await notificationManager.requestAuthorization()
                isLoading = false
            }
        }
    }
}
