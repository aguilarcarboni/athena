import Foundation

class OpenAIService: ObservableObject {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    @Published var isLoading = false
    @Published var error: Error?
    
    private var apiKey: String = "" // Will be set later
    
    func setAPIKey(_ key: String) {
        print("Setting API key: \(key.prefix(10))...")
        apiKey = key
    }
    
    func generatePromptFromAIData(_ aiData: AIDataModel) -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        let currentDate = dateFormatter.string(from: Date())


        var prompt = "Generate a personalized daily summary in a casual but professional tone, like JARVIS from Iron Man. Here's the data:\n\n"
        prompt += "Date: \(currentDate)\n"
        
        // Health Data
        let health = aiData.healthData
        prompt += "\nHealth Data:\n"
        prompt += "- Steps: \(health.steps)\n"
        prompt += "- Heart Rate: \(health.heartRate) bpm\n"
        prompt += "- Sleep Hours: \(health.sleepHours)h\n"
        prompt += "- Active Energy Burned: \(health.activeEnergyBurned) calories\n"
        prompt += "- Exercise Minutes: \(health.exerciseMinutes) minutes\n"
        prompt += "- Time in Daylight: \(health.timeInDaylight) minutes\n"
        
        // Calendar Data
        let calendar = aiData.calendarData
        if !calendar.tomorrowEvents.isEmpty {
            prompt += "\nTomorrow's Events:\n"
            calendar.tomorrowEvents.forEach { event in
                prompt += "- \(event)\n"
            }
        }
        if !calendar.todayEvents.isEmpty {
            prompt += "\nToday's Events:\n"
            calendar.todayEvents.forEach { event in
                prompt += "- \(event)\n"
            }
        }
        
        if !calendar.yesterdayEvents.isEmpty {
            prompt += "\nYesterday's Events:\n"
            calendar.yesterdayEvents.forEach { event in
                prompt += "- \(event)\n"
            }
        }

        // Reminders Data
        if !calendar.tomorrowReminders.isEmpty {
            prompt += "\nTomorrow's Reminders:\n"
            calendar.tomorrowReminders.forEach { reminder in
                prompt += "- \(reminder)\n"
            }
        }
        if !calendar.todayReminders.isEmpty {
            prompt += "\nToday's Reminders:\n"
            calendar.todayReminders.forEach { reminder in
                prompt += "- \(reminder)\n"
            }
        }
        if !calendar.yesterdayReminders.isEmpty {
            prompt += "\nYesterday's Reminders:\n"
            calendar.yesterdayReminders.forEach { reminder in
                prompt += "- \(reminder)\n"
            }
        }
        
        prompt += "\nPlease create a summary that includes:\n"
        prompt += "1. A greeting and quick overview\n"
        prompt += "2. Health insights and recommendations\n"
        prompt += "3. Today's priorities based on calendar events\n"
        prompt += "4. Personalized suggestions for improvement\n"
        prompt += "5. A PS with a practical tip combining health and daily tasks\n"
        
        return prompt
    }
    
    func sendMessage(_ message: String, aiData: AIDataModel? = nil) async throws -> String {
        
        guard !apiKey.isEmpty else {
            print("Error: API Key is empty")
            throw NSError(domain: "OpenAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key not set"])
        }
        
        let systemMessage = "You are a helpful personal assistant that creates casual but useful, motivational daily summaries. Focus on being concise, practical, and encouraging. Dont use headers or subheaders in markdown, simply make titles and key points bold. Use 3 or 4 emojis at most."
        var messages = [ChatMessage(role: "system", content: systemMessage)]
        
        if let data = aiData {
            let dataPrompt = generatePromptFromAIData(data)
            messages.append(ChatMessage(role: "user", content: dataPrompt))
        } else {
            messages.append(ChatMessage(role: "user", content: message))
        }
        
        
        let request = ChatCompletionRequest(model: "gpt-4o-mini", messages: messages)
        
        guard let url = URL(string: baseURL) else {
            print("Error: Invalid URL")
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(request)
            urlRequest.httpBody = encodedData
            if let jsonString = String(data: encodedData, encoding: .utf8) {
                print("Request JSON: \(jsonString)")
            }
        } catch {
            print("Error encoding request: \(error)")
            throw error
        }
        
        print("Sending request to OpenAI API...")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response JSON: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: Invalid HTTP response")
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("Error: API request failed with status code \(httpResponse.statusCode)")
            if let errorJson = String(data: data, encoding: .utf8) {
                print("Error response: \(errorJson)")
            }
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode)"])
        }
        
        let decoder = JSONDecoder()
        do {
            let completionResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
            
            guard let firstChoice = completionResponse.choices.first else {
                print("Error: No choices in response")
                throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response choices available"])
            }
            
            return firstChoice.message.content
        } catch {
            print("Error decoding response: \(error)")
            throw error
        }
    }
} 
