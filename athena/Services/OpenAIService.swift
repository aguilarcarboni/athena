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

    func generateWorkoutSummary(workouts: [HKWorkout]) async throws -> String {
        var prompt = "\nWorkouts:\n"
        for workout in workouts.suffix(10) {
            prompt += "\nNew Workout: \(workout.workoutActivityType.name)\n"
            prompt += "Start: \(workout.startDate.formatted(date: .long, time: .shortened))\n"
            prompt += "End: \(workout.endDate.formatted(date: .long, time: .shortened))\n"
            prompt += String(format: "Duration: %.1f minutes\n", workout.duration/60)
            let desc = workout.description
            if !desc.isEmpty {
                prompt += "Description: \(desc)\n"
            }
            if let distance = workout.totalDistance?.doubleValue(for: .mile()) {
                prompt += String(format: "Distance: %.2f mi\n", distance)
            } else if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                prompt += String(format: "Distance: %.0f m\n", distance)
            }
            if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                prompt += "Calories: \(Int(calories)) kcal\n"
            }
            if let strokes = workout.totalSwimmingStrokeCount?.doubleValue(for: HKUnit.count()) {
                prompt += "Swimming Strokes: \(Int(strokes))\n"
            }
            if let flights = workout.totalFlightsClimbed?.doubleValue(for: HKUnit.count()) {
                prompt += "Flights Climbed: \(Int(flights))\n"
            }
            // Device info
            if let device = workout.device {
                prompt += "Device: \(device.name ?? "Unknown") (\(device.model ?? ""))\n"
            }
            // Metadata
            if let meta = workout.metadata, !meta.isEmpty {
                prompt += "Metadata: "
                for (key, value) in meta {
                    prompt += "\(key): \(value), "
                }
                prompt += "\n"
            }
            // Heart Rate Summary
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
            // Workout Events (pauses, laps, etc.)
            if let events = workout.workoutEvents, !events.isEmpty {
                prompt += "Events: "
                for event in events {
                    prompt += "[\(event.type.rawValue) at \(event.dateInterval.start.formatted(date: .abbreviated, time: .shortened))] "
                }
                prompt += "\n"
            }
            // Workout Activities
            if !workout.workoutActivities.isEmpty {
                prompt += "Workout activities:\n"
                for activity in workout.workoutActivities {
                    prompt += "  - Type: \(activity.workoutConfiguration.activityType.name)\n"
                    prompt += "    Description: \(activity.workoutConfiguration.description)\n"
                    prompt += String(format: "    Duration: %.0f seconds\n", activity.duration)
                }
            }
            prompt += "_______________________\n"
        }
        return prompt
    }

    func generateEventSummary(events: [EKEvent]) -> String {
        var prompt = "\nEvents:\n"
        for event in events {
            prompt += "\n\(event.title ?? "(No Title)")\n"
        }
        return prompt
    }

    func generateReminderSummary(reminders: [EKReminder]) -> String {
        var prompt = "\nReminders:\n"
        for reminder in reminders {
            prompt += "\n\(reminder.title ?? "(No Title)")\n"
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
            prompt += "\n\(data.type.description): \(data.value) \(data.unit)\n"
        }

        prompt += try await generateWorkoutSummary(workouts: workouts)

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

        if !yesterdayEvents.isEmpty {
            prompt += generateEventSummary(events: yesterdayEvents)
        }
        if !yesterdayReminders.isEmpty {
            prompt += generateReminderSummary(reminders: yesterdayReminders)
        }

        // Today
        if !todayEvents.isEmpty {
            prompt += generateEventSummary(events: todayEvents)
        }
        if !todayReminders.isEmpty {
            prompt += generateReminderSummary(reminders: todayReminders)
        }
        
        // Tomorrow
        if !tomorrowEvents.isEmpty {
            prompt += generateEventSummary(events: tomorrowEvents)
        }
        if !tomorrowReminders.isEmpty {
            prompt += generateReminderSummary(reminders: tomorrowReminders)
        }
        
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
        I am basically buddhist, I created my own religion basically.
        I work part time as a Lead Software Engineer.
        I am a full time student at Texas Tech University Costa Rica. Senior. Major in Computer Science. Minor in Mathematics. Currently in summer break.
        I live in Costa Rica.
        I love reading, listening and playing music, gaming, watching movies and coding. I am a huge geek and love sci-fi, Marvel, Star Wars, Lord of the Rings, Breaking Bad, etc. Movies, books and comics.
        I am a high level athlete training towards lifelong fitness and health, love playing any sport like running, yoga, meditation, basketball, soccer, hiking, climbing, golfing, gymnastics and calisthenics.
        I play the guitar and the piano.
        I love mathematics, science, physics, chemistry, neuroscience, etc.
        Want to be a founder and build a company that changes the world.
        """
        let formattingRules = "Use 3 or 4 emojis at most. Never use headers or subheaders in markdown, simply make titles and key points bold."
        let systemMessage = task + "\n\n" + context + "\n\n" + formattingRules

        let prompt = try await generateSummaryPrompt(healthData: healthData, workouts: workouts, events: events, reminders: reminders)

        var messages: [ChatMessage] = []
        messages.append(ChatMessage(role: "system", content: systemMessage))
        messages.append(ChatMessage(role: "user", content: prompt))

        return messages
    }

    func generateWorkoutSummaryMessages(workouts: [HKWorkout]) async throws -> [ChatMessage] {
        let task = """
        You are an assistant that acts as a personalized health and performance advisor for elite athletes who wish to use their accumulated training experience to maintain a healthy, high-functioning lifestyle while still promoting the ability to employ any movement natural to the human body at any point in your life with correct form. This assistant blends the expertise of a fitness coach, physiotherapist, a nutritionist, and a wellness consultant, offering tailored guidance in areas like strength, stability, speed, endurance, agility, power, and mobility. It avoids general fitness advice, instead building nuanced, evidence-informed plans that reflect the user's training background and desire for sustainable performance. The focus is on long-term health, vitality, and an active lifestyle, emphasizing a holistic and strategic approach. Emphasis is placed on real-life applicability, readiness for any sport or physical goal, and tight Mind Muscle Connection. Recovery, adaptability, and progression are prioritized through Test Days, physiological monitoring (e.g., HRV), and qualitative self-awareness. The user loves tech like the Apple Watch to track their workouts. Align new routines or suggestions with the underlying goals of lifelong performance readiness, biomechanical integrity, and system-wide wellness.
        """
        let context = """
        I am Andres.
        I am 22 years old.
        I am basically buddhist, I created my own religion basically.
        I work part time as a Lead Software Engineer.
        I am a full time student at Texas Tech University Costa Rica. Senior. Major in Computer Science. Minor in Mathematics. Currently in summer break.
        I live in Costa Rica.
        I love reading, listening and playing music, gaming, watching movies and coding. I am a huge geek and love sci-fi, Marvel, Star Wars, Lord of the Rings, Breaking Bad, etc. Movies, books and comics.
        I am a high level athlete training towards lifelong fitness and health, love playing any sport like running, yoga, meditation, basketball, soccer, hiking, climbing, golfing, gymnastics and calisthenics.
        I play the guitar and the piano.
        I love mathematics, science, physics, chemistry, neuroscience, etc.
        Want to be a founder and build a company that changes the world.
        
        The user used to be an athlete an now wants a fitness structure that is sustainable and enjoyable, while still promoting the ability to employ any movement natural to the human body at any point in your life with correct form. The user is a former Division 1 athlete and has a strong background in strength training and conditioning, specifically hypertrophy training. The user enjoys sports and being active in general so they want a training plan that is sustainable and healthy to the mind and body. The user likes weight training (of any kind), running, yoga, meditation, basketball, soccer, hiking, climbing, golfing, gymnastics, calisthenics, and more. Recomendations should be based on the users goals and the workouts that have been done. All weight training done is functional and is full of calisthentics, plyometrics, compound movements, and more. Cardio is trained both with aerobic and anaerobic focus, while strength training focuses on being able to employ high strength without losing agility, speed, mobility or prompting an injury.

        We are trying to do three workouts a week, with optional but recommended sports:
        - Upper Body Strength
        - Lower Body Strength
        - Cardio

        Tell the user if they are slacking, and also analyze if the user is unknowingly training some movmeents and exercises more than others, leading to imbalances.
        """

        let formattingRules = "Use 3 or 4 emojis at most. Never use headers or subheaders in markdown, simply make titles and key points bold."

        let systemMessage = task + "\n\n" + context + "\n\n" + formattingRules

        let prompt = try await generateWorkoutSummary(workouts: workouts)

        var messages: [ChatMessage] = []
        messages.append(ChatMessage(role: "system", content: systemMessage))
        messages.append(ChatMessage(role: "user", content: prompt))

        return messages
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
} 
