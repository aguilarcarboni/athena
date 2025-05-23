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
        default: return "figure.heart"
        }
    }
}
