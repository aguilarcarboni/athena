import Foundation
import EventKit

class OpenAIService: ObservableObject {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    @Published var isLoading = false
    @Published var error: Error?
    
    private var apiKey: String = "" // Will be set later
    
    func setAPIKey(_ key: String) {
        print("Setting API key: \(key.prefix(10))...")
        apiKey = key
    }
    
    func generatePrompt(healthManager: HealthManager, events: [EKEvent], reminders: [EKReminder]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        let currentDate = dateFormatter.string(from: Date())

        var prompt = "Generate a personalized daily summary in a casual but professional tone, like JARVIS from Iron Man. Here's the data:\n\n"
        prompt += "Date: \(currentDate)\n"
        
        // Health Data
        prompt += "\nHealth Data:\n"
        prompt += "- Steps: \(healthManager.steps)\n"
        prompt += "- Heart Rate: \(healthManager.heartRate) bpm\n"
        prompt += "- Sleep Hours: \(healthManager.sleepHours)h\n"
        prompt += "- Active Energy Burned: \(healthManager.activeEnergyBurned) calories\n"
        prompt += "- Exercise Minutes: \(healthManager.exerciseMinutes) minutes\n"
        prompt += "- Time in Daylight: \(healthManager.timeInDaylight) minutes\n"
        // Add more health metrics as needed

        // Calendar Data
        let calendar = Calendar.current
        let now = Date()
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        let yesterdayEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: startOfYesterday) }
        let todayEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: startOfToday) }
        let tomorrowEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: startOfTomorrow) }

        let yesterdayReminders = reminders.filter { $0.dueDateComponents?.date != nil && calendar.isDate($0.dueDateComponents!.date!, inSameDayAs: startOfYesterday) }
        let todayReminders = reminders.filter { $0.dueDateComponents?.date != nil && calendar.isDate($0.dueDateComponents!.date!, inSameDayAs: startOfToday) }
        let tomorrowReminders = reminders.filter { $0.dueDateComponents?.date != nil && calendar.isDate($0.dueDateComponents!.date!, inSameDayAs: startOfTomorrow) }

        if !tomorrowEvents.isEmpty {
            prompt += "\nTomorrow's Events:\n"
            tomorrowEvents.forEach { event in
                prompt += "- \(event.title ?? "(No Title)")\n"
            }
        }
        if !todayEvents.isEmpty {
            prompt += "\nToday's Events:\n"
            todayEvents.forEach { event in
                prompt += "- \(event.title ?? "(No Title)")\n"
            }
        }
        if !yesterdayEvents.isEmpty {
            prompt += "\nYesterday's Events:\n"
            yesterdayEvents.forEach { event in
                prompt += "- \(event.title ?? "(No Title)")\n"
            }
        }
        if !tomorrowReminders.isEmpty {
            prompt += "\nTomorrow's Reminders:\n"
            tomorrowReminders.forEach { reminder in
                prompt += "- \(reminder.title ?? "(No Title)")\n"
            }
        }
        if !todayReminders.isEmpty {
            prompt += "\nToday's Reminders:\n"
            todayReminders.forEach { reminder in
                prompt += "- \(reminder.title ?? "(No Title)")\n"
            }
        }
        if !yesterdayReminders.isEmpty {
            prompt += "\nYesterday's Reminders:\n"
            yesterdayReminders.forEach { reminder in
                prompt += "- \(reminder.title ?? "(No Title)")\n"
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
    
    func sendMessage(_ message: String, healthManager: HealthManager, events: [EKEvent], reminders: [EKReminder]) async throws -> String {
        guard !apiKey.isEmpty else {
            print("Error: API Key is empty")
            throw NSError(domain: "OpenAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key not set"])
        }
        let systemMessage = "You are a helpful personal assistant that creates casual but useful, motivational daily summaries. Focus on being concise, practical, and encouraging. Dont use headers or subheaders in markdown, simply make titles and key points bold. Use 3 or 4 emojis at most."
        var messages = [ChatMessage(role: "system", content: systemMessage)]
        let dataPrompt = generatePrompt(healthManager: healthManager, events: events, reminders: reminders)
        messages.append(ChatMessage(role: "user", content: dataPrompt))
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
