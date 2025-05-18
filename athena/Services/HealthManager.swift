import Foundation
import HealthKit

class HealthManager: ObservableObject {
    
    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    static let shared = HealthManager()
    
    // Health Metrics
    @Published var steps: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var basalEnergyBurned: Double = 0
    @Published var distanceWalkingRunning: Double = 0
    @Published var flightsClimbed: Double = 0
    @Published var standHours: Double = 0
    @Published var exerciseMinutes: Double = 0
    @Published var sleepHours: Double = 0
    @Published var bodyMass: Double = 0
    @Published var bodyFatPercentage: Double = 0
    @Published var bodyMassIndex: Double = 0
    @Published var leanBodyMass: Double = 0
    @Published var bodyTemperature: Double = 0
    @Published var bloodPressureSystolic: Double = 0
    @Published var bloodPressureDiastolic: Double = 0
    @Published var bloodOxygen: Double = 0
    @Published var respiratoryRate: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var walkingHeartRateAverage: Double = 0
    @Published var heartRateVariability: Double = 0
    @Published var vo2Max: Double = 0
    @Published var timeInDaylight: Double = 0
    
    func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .leanBodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .timeInDaylight)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchHealthData()
                }
            }
        }
    }
    
    func fetchHealthData() {
        fetchSteps()
        fetchHeartRate()
        fetchActiveEnergyBurned()
        fetchBasalEnergyBurned()
        fetchDistanceWalkingRunning()
        fetchFlightsClimbed()
        fetchStandHours()
        fetchExerciseMinutes()
        fetchSleepHours()
        fetchTimeInDaylight()
        fetchBodyMetrics()
        fetchVitalSigns()
        fetchHeartMetrics()
    }
    
    private func fetchSteps() {
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.steps = sum.doubleValue(for: HKUnit.count())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: heartRateType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.heartRate = mostRecent.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchActiveEnergyBurned() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.activeEnergyBurned = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchBasalEnergyBurned() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.basalEnergyBurned = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchDistanceWalkingRunning() {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.distanceWalkingRunning = sum.doubleValue(for: HKUnit.meter())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchFlightsClimbed() {
        guard let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: flightsType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.flightsClimbed = sum.doubleValue(for: HKUnit.count())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchStandHours() {
        guard let standType = HKQuantityType.quantityType(forIdentifier: .appleStandTime) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: standType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.standHours = sum.doubleValue(for: HKUnit.minute())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchExerciseMinutes() {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.exerciseMinutes = sum.doubleValue(for: HKUnit.minute())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchSleepHours() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            guard let self = self,
                  let sleepSamples = samples as? [HKCategorySample] else { return }
            
            let totalSleepTime = sleepSamples.reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            }
            
            DispatchQueue.main.async {
                self.sleepHours = totalSleepTime / 3600.0 // Convert seconds to hours
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchTimeInDaylight() {
        guard let timeInDaylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: timeInDaylightType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.timeInDaylight = sum.doubleValue(for: HKUnit.minute())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchBodyMetrics() {
        fetchBodyMass()
        fetchBodyFatPercentage()
        fetchBodyMassIndex()
        fetchLeanBodyMass()
    }
    
    private func fetchBodyMass() {
        guard let massType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: massType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.bodyMass = mostRecent.doubleValue(for: HKUnit.pound())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchBodyFatPercentage() {
        guard let fatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: fatType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.bodyFatPercentage = mostRecent.doubleValue(for: HKUnit.percent())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchBodyMassIndex() {
        guard let bmiType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: bmiType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.bodyMassIndex = mostRecent.doubleValue(for: HKUnit.count())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchLeanBodyMass() {
        guard let massType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: massType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.leanBodyMass = mostRecent.doubleValue(for: HKUnit.pound())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchVitalSigns() {
        fetchBodyTemperature()
        fetchBloodPressure()
        fetchBloodOxygen()
        fetchRespiratoryRate()
    }
    
    private func fetchBodyTemperature() {
        guard let tempType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: tempType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.bodyTemperature = mostRecent.doubleValue(for: HKUnit.degreeFahrenheit())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchBloodPressure() {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let systolicQuery = HKStatisticsQuery(
            quantityType: systolicType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.bloodPressureSystolic = mostRecent.doubleValue(for: HKUnit.millimeterOfMercury())
            }
        }
        
        let diastolicQuery = HKStatisticsQuery(
            quantityType: diastolicType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.bloodPressureDiastolic = mostRecent.doubleValue(for: HKUnit.millimeterOfMercury())
            }
        }
        
        healthStore.execute(systolicQuery)
        healthStore.execute(diastolicQuery)
    }
    
    private func fetchBloodOxygen() {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: oxygenType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.bloodOxygen = mostRecent.doubleValue(for: HKUnit.percent())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchRespiratoryRate() {
        guard let rateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: rateType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.respiratoryRate = mostRecent.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartMetrics() {
        fetchRestingHeartRate()
        fetchWalkingHeartRateAverage()
        fetchHeartRateVariability()
        fetchVO2Max()
    }
    
    private func fetchRestingHeartRate() {
        guard let rateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: rateType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.restingHeartRate = mostRecent.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchWalkingHeartRateAverage() {
        guard let rateType = HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: rateType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.walkingHeartRateAverage = mostRecent.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartRateVariability() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: hrvType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.heartRateVariability = mostRecent.doubleValue(for: HKUnit.secondUnit(with: .milli))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchVO2Max() {
        guard let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: vo2MaxType,
            quantitySamplePredicate: predicate,
            options: .mostRecent
        ) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let mostRecent = result.mostRecentQuantity() else { return }
            
            DispatchQueue.main.async {
                self.vo2Max = mostRecent.doubleValue(for: HKUnit.literUnit(with: .milli).unitDivided(by: .minute().unitMultiplied(by: .gramUnit(with: .kilo))))
            }
        }
        healthStore.execute(query)
    }
    
} 
