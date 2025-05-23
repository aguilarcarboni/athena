import SwiftUI

struct ContentView: View {
    @ObservedObject var healthManager: HealthManager = HealthManager.shared
    @ObservedObject var eventManager: EventManager = EventManager.shared
    @ObservedObject var notificationManager: NotificationManager = NotificationManager.shared
    
    var body: some View {
        AggregatorView()
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Aggregator")
            }
        .onAppear {
            healthManager.requestAuthorization()
            eventManager.requestAuthorization()
            Task {
                await notificationManager.requestAuthorization()
                await healthManager.fetchHealthDataFromLast24Hours()
                await healthManager.fetchWorkouts()
            }
        }
    }
}

#Preview {
    ContentView()
}
