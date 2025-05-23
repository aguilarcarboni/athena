import Foundation
import EventKit
import WorkoutKit
import HealthKit

class OpenAIService: ObservableObject {
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    @Published var isLoading = false
    @Published var error: Error?
    
    let healthManager: HealthManager = HealthManager.shared
    
    private var apiKey: String = "" // Will be set later
    
    func setAPIKey(_ key: String) {
        print("Setting API key: \(key.prefix(10))...")
        apiKey = key
    }
    
    func callChatGPT(messages: [ChatMessage]) async throws -> String {
        
        print("Sending request to ChatGPT...")

        guard !apiKey.isEmpty else {
            print("Error: API Key is empty")
            throw NSError(domain: "OpenAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key not set"])
        }

        // Create the request
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
                //print("Request JSON: \(jsonString)")
            }
        } catch {
            print("Error encoding request: \(error)")
            throw error
        }

        // Send the request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        if let jsonString = String(data: data, encoding: .utf8) {
            //print("Response JSON: \(jsonString)")
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

        // Decode the response
        let decoder = JSONDecoder()
        do {
            let completionResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
            guard let firstChoice = completionResponse.choices.first else {
                print("Error: No choices in response")
                throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response choices available"])
            }
            print("Successfully decoded response from ChatGPT")
            return firstChoice.message.content
        } catch {
            print("Error decoding response: \(error)")
            throw error
        }
    }

    func generateEventSummary(events: [EKEvent]) -> String {
        var prompt = ""
        for event in events {
            prompt += "\(event.title ?? "(No Title)")\n"
        }
        return prompt
    }

    func generateReminderSummary(reminders: [EKReminder]) -> String {
        var prompt = ""
        for reminder in reminders {
            prompt += "\(reminder.title ?? "(No Title)")\n"
        }
        return prompt
    }
    
    func generateSummaryPrompt(healthData: [HealthData], workouts: [HKWorkout], events: [EKEvent], reminders: [EKReminder]) async throws -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        let currentDate = dateFormatter.string(from: Date())

        var prompt = "Generate a personalized summary for the data provided:\n\n"
        prompt += "Date and time: \(currentDate)\n"
        
        // Health Data
        prompt += "\nHealth Data:\n"
        for data in healthData {
            prompt += "\(data.type.name): \(data.value) \(data.unit)\n"
        }
        
        // Calendar Data
        let calendar = Calendar.current
        let now = Date()

        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let yesterdayEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: startOfYesterday) }
        let yesterdayReminders = reminders.filter { $0.dueDateComponents?.date != nil && calendar.isDate($0.dueDateComponents!.date!, inSameDayAs: startOfYesterday) }

        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        let todayEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: startOfToday) }
        let todayReminders = reminders.filter { $0.dueDateComponents?.date != nil && calendar.isDate($0.dueDateComponents!.date!, inSameDayAs: startOfToday) }

        let tomorrowEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: startOfTomorrow) }
        let tomorrowReminders = reminders.filter { $0.dueDateComponents?.date != nil && calendar.isDate($0.dueDateComponents!.date!, inSameDayAs: startOfTomorrow) }

        prompt += "\nYesterday:\n"
        prompt += "Events:\n"
        if !yesterdayEvents.isEmpty {
            prompt += generateEventSummary(events: yesterdayEvents)
        } else {
            prompt += "No events scheduled for yesterday.\n"
        }
        prompt += "\n"
        prompt += "Reminders:\n"
        if !yesterdayReminders.isEmpty {
            prompt += generateReminderSummary(reminders: yesterdayReminders)
        } else {
            prompt += "No reminders scheduled for yesterday.\n"
        }

        prompt += "\nToday:\n"
        prompt += "Events:\n"
        if !todayEvents.isEmpty {
            prompt += generateEventSummary(events: todayEvents)
        } else {
            prompt += "No events scheduled for today.\n"
        }
        prompt += "\n"
        prompt += "Reminders:\n"
        if !todayReminders.isEmpty {
            prompt += generateReminderSummary(reminders: todayReminders)
        } else {
            prompt += "No reminders scheduled for today.\n"
        }
        
        prompt += "\nTomorrow:\n"
        prompt += "Events:\n"
        if !tomorrowEvents.isEmpty {
            prompt += generateEventSummary(events: tomorrowEvents)
        } else {
            prompt += "No events scheduled for tomorrow.\n"
        }
        prompt += "\n"
        prompt += "Reminders:\n"
        if !tomorrowReminders.isEmpty {
            prompt += generateReminderSummary(reminders: tomorrowReminders)
        } else {
            prompt += "No reminders scheduled for tomorrow.\n"
        }
        
        prompt += try await generateWorkoutSummary(workouts: workouts)
        
        print(prompt)
        return prompt
    }

    func generateSummaryMessages(healthData: [HealthData], workouts: [HKWorkout], events: [EKEvent], reminders: [EKReminder]) async throws -> [ChatMessage] {

        let task = """
        You are a very helpful personal assistant that creates useful daily summaries focused on the users goals. Focus on being concise, practical, and encouraging. Talk casual but respectful like JARVIS, using sir. The user wants actual tips and recomendations tailored to their health data and goals. You will be provided with specific health data, calendar events and reminders and context about the user. Generate a summary with the following structure that the user can create at any point of the day to aid them in getting their goals done:

        1. A preview of yesterday.
        2. A quick overview of today.
        3. Today's priorities based on calendar events and reminders.
        4. Health trends, insights and recommendations.
        5. Personalized suggestions for improvement.
        """
        let context = """
        I am Andres.
        I am 22 years old.
        I am basically buddhist, I created my own religion basically focused on meditation, mindfulness, self-reflection, and self-improvement.
        I work part time as a Lead Software Engineer.
        I am a full time student at Texas Tech University Costa Rica. Senior. Major in Computer Science. Minor in Mathematics. Currently in summer break.
        I live in Costa Rica.
        I love reading, listening and playing music, gaming, watching movies and coding. I am a huge geek and love sci-fi, Marvel, Star Wars, Lord of the Rings, Breaking Bad, etc. Movies, books and comics.
        I am a high level athlete training towards lifelong fitness and health, love playing any sport like running, yoga, meditation, basketball, soccer, hiking, climbing, golfing, gymnastics and calisthenics.
        I play the guitar and the piano.
        I love mathematics, science, physics, chemistry, neuroscience, etc.
        Want to be a founder and build a company that changes the world.
        Currently doing a 3 day workout split focused on The ability to employ strength, stability, speed, endurance, agility, power and mobility at any point in your life with correct form for many and any different movements natural to the human body. Working upper body, lower body and cardio with optional sports days.
        """
        let formattingRules = "Use 3 or 4 emojis at most. Never use headers or subheaders in markdown, simply make titles and key points bold."
        let systemMessage = task + "\n\n" + context + "\n\n" + formattingRules

        let prompt = try await generateSummaryPrompt(healthData: healthData, workouts: workouts, events: events, reminders: reminders)

        var messages: [ChatMessage] = []
        messages.append(ChatMessage(role: "system", content: systemMessage))
        messages.append(ChatMessage(role: "user", content: prompt))

        return messages
    }

    private func generateWorkoutSummary(workouts: [HKWorkout]) async throws -> String {
        var prompt = "\nPrevious 5 Workouts:\n"
        for workout in workouts.suffix(5) {
            prompt += "\(workout.workoutActivityType.name)\n"
            if let device = workout.device {
                prompt += "Device: \(device.name ?? "Unknown") (\(device.model ?? ""))\n"
            }
            if let meta = workout.metadata, !meta.isEmpty {
                for (key, value) in meta {
                    prompt += "\(key): \(value)"
                    prompt += "\n"
                }
            }
            prompt += "Start: \(workout.startDate.formatted(date: .long, time: .shortened))\n"
            prompt += "End: \(workout.endDate.formatted(date: .long, time: .shortened))\n"

            let duration = workout.duration
            prompt += String(format: "Duration: %.1f minutes\n", duration/60)
            
            let distance = workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity()?.doubleValue(for: .meter())
            
            if let distance = distance {
                prompt += String(format: "Distance: %.2f m\n", distance)
            }

            if let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                prompt += "Calories: \(Int(calories)) kcal\n"
            }

            let pace = (distance != nil && duration > 0) ? duration / (distance! / 1000.0) : nil // min/km
            if pace != 0 {
                prompt += String(format: "Pace: %.1f min/km\n", pace ?? 0)
            }

            // Average cadence

            // Elevation gain

            if let strokes = workout.statistics(for: HKQuantityType(.swimmingStrokeCount))?.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                prompt += "Swimming Strokes: \(Int(strokes))\n"
            }
            if let flights = workout.statistics(for: HKQuantityType(.flightsClimbed))?.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                prompt += "Flights Climbed: \(Int(flights))\n"
            }

            do {
                let hrData = try await healthManager.fetchHeartRateData(for: workout)
                if !hrData.isEmpty {
                    let minHR = hrData.min() ?? 0
                    let maxHR = hrData.max() ?? 0
                    let avgHR = hrData.reduce(0, +) / Double(hrData.count)
                    prompt += String(format: "Heart Rate (bpm): min %.0f, max %.0f, avg %.0f\n", minHR, maxHR, avgHR)
                }
            } catch {
                prompt += "Heart Rate: unavailable\n"
            }
            
            // WorkoutPlan
            if let workoutPlan = try await workout.workoutPlan {
                //prompt += "Workout Plan: \(workoutPlan)\n"
            }

            if !workout.workoutActivities.isEmpty {
                prompt += "Intervals:\n"
                let activityMetrics = await healthManager.fetchActivityMetrics(for: workout)
                for metrics in activityMetrics {
                    let activity = metrics.activity
                    prompt += "  - Type: \(activity.workoutConfiguration.activityType.name)\n"
                    prompt += String(format: "    Duration: %.0f seconds\n", activity.duration)
                    if let cals = metrics.calories {
                        prompt += String(format: "    Calories: %.0f kcal\n", cals)
                    }
                    if let dist = metrics.distance {
                        if dist > 1000 {
                            prompt += String(format: "    Distance: %.2f km\n", dist/1000)
                        } else {
                            prompt += String(format: "    Distance: %.0f m\n", dist)
                        }
                    }
                    if let pace = metrics.pace {
                        prompt += String(format: "    Pace: %.2f min/km\n", pace/60)
                    }
                    if let minHR = metrics.minHR, let maxHR = metrics.maxHR, let avgHR = metrics.avgHR {
                        prompt += String(format: "    Heart Rate (bpm): min %.0f, max %.0f, avg %.0f\n", minHR, maxHR, avgHR)
                    }
                }
            }
            prompt += "______________________________________________\n"
        }
        return prompt
    }
    
} 
