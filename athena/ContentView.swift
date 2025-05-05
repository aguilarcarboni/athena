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
    @StateObject private var sharedDataManager: SharedDataManager
    
    init() {
        let healthManager = HealthManager()
        let eventManager = EventManager()
        _healthManager = StateObject(wrappedValue: healthManager)
        _eventManager = StateObject(wrappedValue: eventManager)
        _sharedDataManager = StateObject(wrappedValue: SharedDataManager(healthManager: healthManager, eventManager: eventManager))
    }
    
    var body: some View {
        AggregatorView(healthManager: healthManager, eventManager: eventManager, sharedDataManager: sharedDataManager)
    }
}

#Preview {
    ContentView()
}
