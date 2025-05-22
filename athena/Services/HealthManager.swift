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

class HealthManager: ObservableObject {
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    static let shared = HealthManager()

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
            unit: HKUnit.count(), 
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

    func fetchHealthDataFromLast24Hours() async -> [HealthData] {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            var pendingQueries = data.count
            var updatedData = self.data

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
                            continuation.resume(returning: updatedData)
                        }
                    }
                }
                healthStore.execute(query)
            }
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
    
} 

enum HealthError: Error {
    case dataTypeNotAvailable
    case invalidData
}
