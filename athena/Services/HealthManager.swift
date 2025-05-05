import Foundation
import HealthKit

class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    
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
    
    // AI Data
    @Published var aiData: AIDataModel?
    
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
            HKObjectType.quantityType(forIdentifier: .timeInDaylight)!
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
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
                self.updateAIData()
            }
        }
        healthStore.execute(query)
    }
    
    private func updateAIData() {
        // Create health data model
        let healthData = AIDataModel.HealthData(
            steps: steps,
            heartRate: heartRate,
            activeEnergyBurned: activeEnergyBurned,
            basalEnergyBurned: basalEnergyBurned,
            distanceWalkingRunning: distanceWalkingRunning,
            flightsClimbed: flightsClimbed,
            standHours: standHours,
            exerciseMinutes: exerciseMinutes,
            sleepHours: sleepHours,
            timeInDaylight: timeInDaylight,
            bodyMass: bodyMass,
            bodyFatPercentage: bodyFatPercentage,
            bodyMassIndex: bodyMassIndex,
            leanBodyMass: leanBodyMass,
            bodyTemperature: bodyTemperature,
            bloodPressureSystolic: bloodPressureSystolic,
            bloodPressureDiastolic: bloodPressureDiastolic,
            bloodOxygen: bloodOxygen,
            respiratoryRate: respiratoryRate,
            restingHeartRate: restingHeartRate,
            walkingHeartRateAverage: walkingHeartRateAverage,
            heartRateVariability: heartRateVariability,
            vo2Max: vo2Max,
            peakExpiratoryFlowRate: 0,
            forcedExpiratoryVolume1: 0,
            forcedVitalCapacity: 0,
            inhalerUsage: 0,
            insulinDelivery: 0,
            bloodGlucose: 0,
            dietaryEnergy: 0,
            dietaryProtein: 0,
            dietaryCarbohydrates: 0,
            dietaryFatTotal: 0,
            dietaryFatSaturated: 0,
            dietaryFatPolyunsaturated: 0,
            dietaryFatMonounsaturated: 0,
            dietaryCholesterol: 0,
            dietarySodium: 0,
            dietaryFiber: 0,
            dietarySugar: 0,
            dietaryVitaminA: 0,
            dietaryVitaminB6: 0,
            dietaryVitaminB12: 0,
            dietaryVitaminC: 0,
            dietaryVitaminD: 0,
            dietaryVitaminE: 0,
            dietaryVitaminK: 0,
            dietaryCalcium: 0,
            dietaryIron: 0,
            dietaryThiamin: 0,
            dietaryRiboflavin: 0,
            dietaryNiacin: 0,
            dietaryFolate: 0,
            dietaryBiotin: 0,
            dietaryPantothenicAcid: 0,
            dietaryPhosphorus: 0,
            dietaryIodine: 0,
            dietaryMagnesium: 0,
            dietaryZinc: 0,
            dietarySelenium: 0,
            dietaryCopper: 0,
            dietaryManganese: 0,
            dietaryChromium: 0,
            dietaryMolybdenum: 0,
            dietaryChloride: 0,
            dietaryPotassium: 0,
            dietaryCaffeine: 0,
            dietaryWater: 0,
            dietaryAlcohol: 0,
            dietaryEnergyConsumed: 0,
            dietaryEnergyBurned: 0,
            dietaryEnergyGoal: 0,
            dietaryEnergyRemaining: 0,
            dietaryEnergyPercentage: 0,
            dietaryProteinGoal: 0,
            dietaryProteinRemaining: 0,
            dietaryProteinPercentage: 0,
            dietaryCarbohydratesGoal: 0,
            dietaryCarbohydratesRemaining: 0,
            dietaryCarbohydratesPercentage: 0,
            dietaryFatTotalGoal: 0,
            dietaryFatTotalRemaining: 0,
            dietaryFatTotalPercentage: 0,
            dietaryFatSaturatedGoal: 0,
            dietaryFatSaturatedRemaining: 0,
            dietaryFatSaturatedPercentage: 0,
            dietaryFatPolyunsaturatedGoal: 0,
            dietaryFatPolyunsaturatedRemaining: 0,
            dietaryFatPolyunsaturatedPercentage: 0,
            dietaryFatMonounsaturatedGoal: 0,
            dietaryFatMonounsaturatedRemaining: 0,
            dietaryFatMonounsaturatedPercentage: 0,
            dietaryCholesterolGoal: 0,
            dietaryCholesterolRemaining: 0,
            dietaryCholesterolPercentage: 0,
            dietarySodiumGoal: 0,
            dietarySodiumRemaining: 0,
            dietarySodiumPercentage: 0,
            dietaryFiberGoal: 0,
            dietaryFiberRemaining: 0,
            dietaryFiberPercentage: 0,
            dietarySugarGoal: 0,
            dietarySugarRemaining: 0,
            dietarySugarPercentage: 0,
            dietaryVitaminAGoal: 0,
            dietaryVitaminARemaining: 0,
            dietaryVitaminAPercentage: 0,
            dietaryVitaminB6Goal: 0,
            dietaryVitaminB6Remaining: 0,
            dietaryVitaminB6Percentage: 0,
            dietaryVitaminB12Goal: 0,
            dietaryVitaminB12Remaining: 0,
            dietaryVitaminB12Percentage: 0,
            dietaryVitaminCGoal: 0,
            dietaryVitaminCRemaining: 0,
            dietaryVitaminCPercentage: 0,
            dietaryVitaminDGoal: 0,
            dietaryVitaminDRemaining: 0,
            dietaryVitaminDPercentage: 0,
            dietaryVitaminEGoal: 0,
            dietaryVitaminERemaining: 0,
            dietaryVitaminEPercentage: 0,
            dietaryVitaminKGoal: 0,
            dietaryVitaminKRemaining: 0,
            dietaryVitaminKPercentage: 0,
            dietaryCalciumGoal: 0,
            dietaryCalciumRemaining: 0,
            dietaryCalciumPercentage: 0,
            dietaryIronGoal: 0,
            dietaryIronRemaining: 0,
            dietaryIronPercentage: 0,
            dietaryThiaminGoal: 0,
            dietaryThiaminRemaining: 0,
            dietaryThiaminPercentage: 0,
            dietaryRiboflavinGoal: 0,
            dietaryRiboflavinRemaining: 0,
            dietaryRiboflavinPercentage: 0,
            dietaryNiacinGoal: 0,
            dietaryNiacinRemaining: 0,
            dietaryNiacinPercentage: 0,
            dietaryFolateGoal: 0,
            dietaryFolateRemaining: 0,
            dietaryFolatePercentage: 0,
            dietaryBiotinGoal: 0,
            dietaryBiotinRemaining: 0,
            dietaryBiotinPercentage: 0,
            dietaryPantothenicAcidGoal: 0,
            dietaryPantothenicAcidRemaining: 0,
            dietaryPantothenicAcidPercentage: 0,
            dietaryPhosphorusGoal: 0,
            dietaryPhosphorusRemaining: 0,
            dietaryPhosphorusPercentage: 0,
            dietaryIodineGoal: 0,
            dietaryIodineRemaining: 0,
            dietaryIodinePercentage: 0,
            dietaryMagnesiumGoal: 0,
            dietaryMagnesiumRemaining: 0,
            dietaryMagnesiumPercentage: 0,
            dietaryZincGoal: 0,
            dietaryZincRemaining: 0,
            dietaryZincPercentage: 0,
            dietarySeleniumGoal: 0,
            dietarySeleniumRemaining: 0,
            dietarySeleniumPercentage: 0,
            dietaryCopperGoal: 0,
            dietaryCopperRemaining: 0,
            dietaryCopperPercentage: 0,
            dietaryManganeseGoal: 0,
            dietaryManganeseRemaining: 0,
            dietaryManganesePercentage: 0,
            dietaryChromiumGoal: 0,
            dietaryChromiumRemaining: 0,
            dietaryChromiumPercentage: 0,
            dietaryMolybdenumGoal: 0,
            dietaryMolybdenumRemaining: 0,
            dietaryMolybdenumPercentage: 0,
            dietaryChlorideGoal: 0,
            dietaryChlorideRemaining: 0,
            dietaryChloridePercentage: 0,
            dietaryPotassiumGoal: 0,
            dietaryPotassiumRemaining: 0,
            dietaryPotassiumPercentage: 0,
            dietaryCaffeineGoal: 0,
            dietaryCaffeineRemaining: 0,
            dietaryCaffeinePercentage: 0,
            dietaryWaterGoal: 0,
            dietaryWaterRemaining: 0,
            dietaryWaterPercentage: 0,
            dietaryAlcoholGoal: 0,
            dietaryAlcoholRemaining: 0,
            dietaryAlcoholPercentage: 0
        )
        
        // Note: Calendar data will be added by EventManager
        self.aiData = AIDataModel(
            timestamp: Date(),
            healthData: healthData,
            calendarData: AIDataModel.CalendarData(
                todayEvents: [],
                yesterdayEvents: [],
                tomorrowEvents: [],
                todayReminders: [],
                yesterdayReminders: [],
                tomorrowReminders: []
            )
        )
    }
} 
