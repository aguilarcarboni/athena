import SwiftUI

struct SummarizerView: View {
    @StateObject private var openAIService = OpenAIService()
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var summaryResponse: String = ""
    @State private var errorMessage: String? = nil
    @State private var showSheet = false
    @State private var paragraphCount: Int = 3
    
    var body: some View {
        NavigationView {
            ZStack {

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Paragraphs: \(paragraphCount)")
                                .font(.subheadline)
                            Spacer()
                        }
                        Slider(value: Binding(
                            get: { Double(paragraphCount) },
                            set: { paragraphCount = Int($0) }
                        ), in: 2...5, step: 1)
                    }
                    .padding([.horizontal, .top], 16)

                    TextEditor(text: $inputText)
                        .textEditorStyle(.plain)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .font(.body)
                        .padding([.horizontal, .top], 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)

                    Spacer()
                    
                }
            }
            .navigationTitle("Text Summarizer")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        showSheet = true
                        summarizeText()
                    }) {
                        HStack {
                            Image(systemName: "text.append")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
            .sheet(isPresented: $showSheet, onDismiss: resetSheet) {
                VStack(alignment: .leading) {
                    Text("Summary")
                        .font(.title2).bold()
                        .padding(.bottom, 8)
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView("Athena is thinking...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                        Spacer()
                    } else if !summaryResponse.isEmpty {
                        ScrollView {
                            Text(LocalizedStringKey(summaryResponse))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        Spacer()
                    } else {
                        Spacer()
                    }

                }
                .padding()
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func summarizeText() {
        let prompt = "Summarize the following text in \(paragraphCount) concise paragraphs, focusing on the main points and clarity.\n\n" + inputText
        isLoading = true
        errorMessage = nil
        summaryResponse = ""
        Task {
            do {
                let response = try await openAIService.sendMessage(prompt)
                summaryResponse = response
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func resetSheet() {
        isLoading = false
        summaryResponse = ""
        errorMessage = nil
    }
}


#Preview {
    SummarizerView()
}
