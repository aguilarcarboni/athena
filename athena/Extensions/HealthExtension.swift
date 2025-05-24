import HealthKit

extension HKQuantityType {
    var name: String {
        switch self {
        case HKObjectType.quantityType(forIdentifier: .stepCount)!:
            return "Steps"
        case HKObjectType.quantityType(forIdentifier: .heartRate)!:
            return "Heart Rate"
        case HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!:
            return "Active Energy Burned"
        case HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!:
            return "Exercise Time"
        case HKObjectType.quantityType(forIdentifier: .appleMoveTime)!:
            return "Move Time"
        case HKObjectType.quantityType(forIdentifier: .appleStandTime)!:
            return "Stand Time"
        case HKObjectType.quantityType(forIdentifier: .flightsClimbed)!:
            return "Flights Climbed"
        case HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!:
            return "Heart Rate Variability"
        case HKObjectType.quantityType(forIdentifier: .timeInDaylight)!:
            return "Time in Daylight"
        default:
            return "Test"
        }
    }
}

extension HKQuantityType {
    var icon: String {
        switch self {
        case HKObjectType.quantityType(forIdentifier: .stepCount)!: return "figure.walk"
        case HKObjectType.quantityType(forIdentifier: .heartRate)!: return "heart.fill"
        case HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!: return "figure.run"
        case HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!: return "figure.outdoor.cycle"
        case HKObjectType.quantityType(forIdentifier: .appleMoveTime)!: return "figure.hiking"
        case HKObjectType.quantityType(forIdentifier: .appleStandTime)!: return "figure.hiking"
        case HKObjectType.quantityType(forIdentifier: .flightsClimbed)!: return "figure.hiking"
        case HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!: return "figure.hiking"
        case HKObjectType.quantityType(forIdentifier: .timeInDaylight)!: return "figure.hiking"
        default: return "heart.fill"
        }
    }
}
