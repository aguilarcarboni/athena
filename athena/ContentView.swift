//
//  ContentView.swift
//  athena
//
//  Created by Andrés on 27/4/2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var healthManager: HealthManager = HealthManager.shared
    @ObservedObject var eventManager: EventManager = EventManager.shared
    
    var body: some View {
        TabView {
            AggregatorView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Aggregator")
                }
            FitnessView()
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("Fitness")
                }
        }
        .onAppear {
            healthManager.requestAuthorization()
            eventManager.requestAuthorization()
            Task {
                await healthManager.fetchHealthDataFromLast24Hours()
                await healthManager.fetchWorkouts()
            }
        }
    }
}

#Preview {
    ContentView()
}
