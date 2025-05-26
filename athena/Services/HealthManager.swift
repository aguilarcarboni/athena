import Foundation
import HealthKit
import WorkoutKit

struct DailySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let duration: Double
}

struct LatestMindfulSessionData: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let duration: Double
}

struct HealthData {
    let id = UUID()
    let type: HKQuantityType
    var value: Double
    let unit: HKUnit
    let typeOfData: HKStatisticsOptions
}

struct ActivityMetrics {
    let activity: HKWorkoutActivity
    let startDate: Date
    let endDate: Date
    let duration: Double?
    let calories: Double?
    let distance: Double?
    let pace: Double?
    let minHR: Double?
    let maxHR: Double?
    let avgHR: Double?
}

class HealthManager: ObservableObject {
    
    private let healthStore = HKHealthStore()
    static let shared = HealthManager()

    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!

    private let cumulativeCountTypes: Set<HKQuantityType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
    ]
    
    private let cumulativeTimeTypes: Set<HKQuantityType> = [
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKQuantityType.quantityType(forIdentifier: .appleMoveTime)!,
        HKQuantityType.quantityType(forIdentifier: .appleStandTime)!,
        HKQuantityType.quantityType(forIdentifier: .timeInDaylight)!
    ]

    private let cumulativeCaloriesTypes: Set<HKQuantityType> = [
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
    ]
    
    @Published var isAuthorized = false

    @Published var workouts: [HKWorkout] = []
    @Published var dailySleepData: [DailySleepData] = []
    @Published var latestMindfulSession: LatestMindfulSessionData?
    @Published var todayData: [HealthData] = []
    @Published var typesToRequest: Set<HKObjectType> = []

    init() {
        self.typesToRequest = Set([sleepType, mindfulSessionType]).union(cumulativeCountTypes).union(cumulativeCaloriesTypes)
        for type in cumulativeCountTypes {
            self.todayData.append(
                HealthData(
                    type: type,
                    value: 0,
                    unit: HKUnit.count(),
                    typeOfData: .cumulativeSum
                )
            )
        }
        
        for type in cumulativeTimeTypes {
            self.todayData.append(
                HealthData(
                    type: type,
                    value: 0,
                    unit: HKUnit.minute(),
                    typeOfData: .cumulativeSum
                )
            )
        }

        for type in cumulativeCaloriesTypes {
            self.todayData.append(
                HealthData(
                    type: type,
                    value: 0,
                    unit: HKUnit.kilocalorie(),
                    typeOfData: .cumulativeSum
                )
            )
        }

        fetchWorkouts()
        fetchHealthDataFromToday()
        fetchSleepDataFromLast7Days()
        fetchLatestMindfulSession()
    }

    func requestAuthorization() {

        healthStore.requestAuthorization(toShare: nil, read: typesToRequest) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
            }
        }
    }

    // Fetch sleep data from the last 7 days
    func fetchSleepDataFromLast7Days() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: sleepType,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { [weak self] _, samples, error in
            guard let self = self,
                  let samples = samples as? [HKCategorySample],
                  error == nil else {
                return
            }

            var sleepDict: [Date: Double] = [:]

            for sample in samples {
                // Filter for actual sleep values
                if HKCategoryValueSleepAnalysis.allAsleepValues.contains(HKCategoryValueSleepAnalysis(rawValue: sample.value)!) {
                    let sleepStart = sample.startDate
                    let sleepEnd = sample.endDate
                    let duration = sleepEnd.timeIntervalSince(sleepStart) / 60.0 // Convert to minutes

                    // Determine the date to assign the sleep to
                    let components = calendar.dateComponents([.year, .month, .day], from: sleepStart)
                    if let date = calendar.date(from: components) {
                        sleepDict[date, default: 0.0] += duration
                    }
                }
            }

            // Convert the dictionary to an array of DailySleepData
            let dailyData = sleepDict.map { DailySleepData(date: $0.key, duration: $0.value) }
                .sorted { $0.date < $1.date }

            DispatchQueue.main.async {
                self.dailySleepData = dailyData
            }
        }

        healthStore.execute(query)
    }
    
    // Fetch the latest mindful session
    func fetchLatestMindfulSession() {
        
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: mindfulType,
                                  predicate: nil,
                                  limit: 1,
                                  sortDescriptors: [sortDescriptor]) { (_, samples, error) in
            guard let sample = samples?.first as? HKCategorySample, error == nil else {
                print("Error fetching latest mindful session: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            
            DispatchQueue.main.async {
                self.latestMindfulSession = LatestMindfulSessionData(
                    startDate: sample.startDate, endDate: sample.endDate, duration: duration)
            }
        }

        healthStore.execute(query)
    }

    // Fetch health data from the last 24 hours
    func fetchHealthDataFromToday() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        var updatedData = self.todayData
        var pendingQueries = self.todayData.count
        
        for (index, data) in todayData.enumerated() {
            let query = HKStatisticsQuery(
                quantityType: data.type,
                quantitySamplePredicate: predicate,
                options: data.typeOfData
            ) { [weak self] _, result, error in
                DispatchQueue.main.async {
                    if let result = result, let sum = result.sumQuantity() {
                        updatedData[index].value = sum.doubleValue(for: data.unit)
                    }
                    pendingQueries -= 1
                    if pendingQueries == 0 {
                        self?.todayData = updatedData
                    }
                }
            }
            healthStore.execute(query)
        }
    }

    // Fetch all workouts
    func fetchWorkouts() {
        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
            guard let self = self,
                  let workouts = samples as? [HKWorkout] else { return }
            DispatchQueue.main.async {
                self.workouts = workouts
            }
        }
        healthStore.execute(query)
    }

    // Fetch heart rate data for a specific workout
    func fetchHeartRateData(for workout: HKWorkout) async throws -> [Double] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthError.dataTypeNotAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate)
        
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { (query, samples, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(throwing: HealthError.invalidData)
                    return
                }
                
                continuation.resume(returning: samples)
            }
            
            healthStore.execute(query)
        }
        
        return samples.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
    }

    func fetchWorkoutPlanDetails(for workout: HKWorkout) async -> String {
        var prompt = ""
        let activityMetrics = await fetchActivityMetrics(for: workout)
        do {
            if let plan = try await workout.workoutPlan {
                switch plan.workout {
                case .custom(let customWorkout):
                    prompt += "Workout Focus: \(customWorkout.displayName ?? "Undefined")\n"
                    
                    // Warmup
                    if let warmup = customWorkout.warmup {
                        prompt += "Warmup Goal: \(warmup.goal)\n"
                    }
                    
                    // Blocks
                    // The activity metrics are already calculated, just loop through them and add the details to the prompt here, you can assume the metrics are in the same order as the steps. If the metrics run out no problem, it means the workout wasnt done fully.
                    for (index, block) in customWorkout.blocks.enumerated() {
                        prompt += "Workout #\(index + 1):\n"
                        prompt += "Iterations: \(block.iterations)\n"
                        
                        for (stepIndex, step) in block.steps.enumerated() {
                            if let name = step.step.displayName {
                                prompt += "Name: \(name)\n"
                            }
                            prompt += "Goal: \(step.step.goal)\n"
                            
                            if let alert = step.step.alert {
                                prompt += "Alert: \(alert)\n"
                            }

                            // Insert corresponding activity metrics if available
                            /*
                            let flatStepIndex = customWorkout.blocks[0..<index].flatMap { $0.steps }.count + stepIndex
                            if flatStepIndex < activityMetrics.count {
                                let metrics = activityMetrics[flatStepIndex]
                                
                                prompt += "\nMetrics:\n"
                                if let duration = metrics.duration {
                                    prompt += "Duration: \(duration / 60.0) min\n"
                                }
                                if let distance = metrics.distance {
                                    prompt += "Distance: \(distance / 1000.0) km\n"
                                }
                                if let pace = metrics.pace {
                                    prompt += "Pace: \(pace) min/km\n"
                                }
                                if let calories = metrics.calories {
                                    prompt += "Calories: \(calories) kcal\n"
                                }
                                if let avgHR = metrics.avgHR {
                                    prompt += "Avg HR: \(avgHR) bpm\n"
                                }
                                if let minHR = metrics.minHR, let maxHR = metrics.maxHR {
                                    prompt += "HR Range: \(minHR)–\(maxHR) bpm\n"
                                }
                            }
                            */
                        }
                        print("\n\n")
                    }
                    
                    // Cooldown
                    if let cooldown = customWorkout.cooldown {
                        prompt += "Cooldown Goal: \(cooldown.goal)\n"
                    }
                    
                case .goal(let goalWorkout):
                    prompt += "Goal Workout Activity: \(goalWorkout.activity)\n"
                    prompt += "Goal: \(goalWorkout.goal)\n"
                    
                case .pacer(let pacerWorkout):
                    prompt += "Pacer Workout Activity: \(pacerWorkout.activity)\n"
                    
                case .swimBikeRun(let triWorkout):
                    prompt += "Swim-Bike-Run Workout Activity: \(triWorkout)\n"
                    
                @unknown default:
                    break
                }
                
            } else {
                print("No workout plan associated with this workout.")
            }
        } catch {
            print("Error fetching workout plan: \(error)")
        }
        return prompt
    }

    // Fetch metrics for each workout activity (interval) in a workout
    func fetchActivityMetrics(for workout: HKWorkout) async -> [ActivityMetrics] {
        guard !workout.workoutActivities.isEmpty else { return [] }
        var results: [ActivityMetrics] = []
        for activity in workout.workoutActivities {

            let calories = activity.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
            let distance = activity.statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity()?.doubleValue(for: .meter())
            
            guard let endDate = activity.endDate else {
                continue // Skip this activity if dates are missing
            }
            let duration = endDate.timeIntervalSince(activity.startDate)
            
            let pace = (distance != nil && duration > 0) ? duration / (distance! / 1000.0) : nil // min/km
        
        
        // Heart rate during this interval
        var minHR: Double? = nil
        var maxHR: Double? = nil
        var avgHR: Double? = nil
        do {
            let hrData = try await fetchHeartRateData(for: activity.startDate, end: endDate)
            if !hrData.isEmpty {
                minHR = hrData.min()
                maxHR = hrData.max()
                avgHR = hrData.reduce(0, +) / Double(hrData.count)
            }
        } catch {
            // Leave HR as nil if not available
        }
            results.append(ActivityMetrics(
                activity: activity,
                startDate: activity.startDate,
                endDate: endDate,
                duration: duration,
                calories: calories,
                distance: distance,
                pace: pace,
                minHR: minHR,
                maxHR: maxHR,
                avgHR: avgHR
            ))
        }
        return results
    }

    // Fetch heart rate data for a specific time window
    func fetchHeartRateData(for start: Date, end: Date) async throws -> [Double] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthError.dataTypeNotAvailable
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { (query, samples, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(throwing: HealthError.invalidData)
                    return
                }
                continuation.resume(returning: samples)
            }
            healthStore.execute(query)
        }
        return samples.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
    }

    
}

enum HealthError: Error {
    case dataTypeNotAvailable
    case invalidData
}
