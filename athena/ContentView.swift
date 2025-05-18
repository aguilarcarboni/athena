//
//  ContentView.swift
//  athena
//
//  Created by Andrés on 27/4/2025.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var healthManager = HealthManager()
    @StateObject private var eventManager = EventManager()
    
    var body: some View {
        TabView {
            AggregatorView(healthManager: healthManager, eventManager: eventManager)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Aggregator")
                }

            SummarizerView()
                .tabItem {
                    Image(systemName: "text.bubble.fill")
                    Text("Summarizer")
                }
        }
    }
}

#Preview {
    ContentView()
}
