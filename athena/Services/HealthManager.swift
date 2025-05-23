import Foundation
import HealthKit
import WorkoutKit

struct HealthData {
    let id: Int
    let type: HKQuantityType
    var value: Double
    let unit: HKUnit
    let typeOfData: HKStatisticsOptions
}

struct ActivityMetrics {
    let activity: HKWorkoutActivity
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
    @Published var isAuthorized = false

    @Published var data: [HealthData] = [
        HealthData(
            id: 0,
            type: HKObjectType.quantityType(forIdentifier: .stepCount)!, 
            value: 0, 
            unit: HKUnit.count(), 
            typeOfData: .cumulativeSum
        ),
        HealthData(
            id: 1,
            type: HKObjectType.quantityType(forIdentifier: .heartRate)!, 
            value: 0, 
            unit: HKUnit.count(), 
            typeOfData: .discreteAverage
        ),
        HealthData(
            id: 2,
            type: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            value: 0,
            unit: HKUnit.kilocalorie(),
            typeOfData: .cumulativeSum
        ),
        HealthData(
            id: 3,
            type: HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            value: 0,
            unit: HKUnit.minute(), 
            typeOfData: .cumulativeSum
        ),
        HealthData(
            id: 4,
            type: HKObjectType.quantityType(forIdentifier: .appleMoveTime)!,
            value: 0,
            unit: HKUnit.minute(), 
            typeOfData: .cumulativeSum
        ),
        HealthData(
            id: 4,
            type: HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            value: 0,
            unit: HKUnit.minute(),
            typeOfData: .cumulativeSum
        ),
    ]

    @Published var workouts: [HKWorkout] = []

    func requestAuthorization() {

        var typesToRead: Set<HKObjectType> = []
        for type in data {
            typesToRead.insert(type.type)
        }

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
            }
        }
    }

    func fetchHealthDataFromLast24Hours() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        var updatedData = self.data
        var pendingQueries = self.data.count
        
        for (index, data) in data.enumerated() {
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
                        self?.data = updatedData
                    }
                }
            }
            healthStore.execute(query)
        }
    }

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
    
} 

enum HealthError: Error {
    case dataTypeNotAvailable
    case invalidData
}
