import SwiftUI
import EventKit

struct SummaryView: View {
    
    let healthManager: HealthManager = HealthManager.shared
    let eventManager: EventManager = EventManager.shared

    @StateObject private var openAIService = OpenAIService()
    @State private var isLoading = false
    @State private var summaryResponse: String = ""
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Athena is thinking...")
                        .padding()
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if !summaryResponse.isEmpty {
                    ScrollView {
                        Text(LocalizedStringKey(summaryResponse))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                } else {
                    Text("No summary available or data provided.")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationTitle("Athena's Daily Summary")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                generateSummary()
            }
        }
    }
    
    private func generateSummary() {
        isLoading = true
        errorMessage = nil
        summaryResponse = ""
        
        Task {
            do {
                let messages: [ChatMessage]
                messages = try await openAIService.generateSummaryMessages(
                        healthData: healthManager.data,
                        workouts: healthManager.workouts,
                        events: eventManager.events.map { $0.event },
                        reminders: eventManager.reminders
                    )
                summaryResponse = try await openAIService.callChatGPT(messages: messages)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
