import SwiftUI

struct SummaryView: View {
    
    let aiData: AIDataModel?
    
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
            .navigationTitle("Athena's Summary")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                generateSummary()
            }
        }
    }
    
    private func generateSummary() {
        guard let data = aiData else {
            errorMessage = "No data provided to generate summary."
            print(errorMessage!)
            return
        }
        
        isLoading = true
        errorMessage = nil
        summaryResponse = ""
        
        Task {
            do {
                summaryResponse = try await openAIService.sendMessage("Generate daily summary", aiData: aiData)
                print("Generated summary response: \(summaryResponse)")
            } catch {
                errorMessage = error.localizedDescription
                print("Error generating summary in SummaryView: \(error)")
            }
            isLoading = false
        }
    }
}
