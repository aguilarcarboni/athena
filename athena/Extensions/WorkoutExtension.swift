import Foundation
import WorkoutKit
import HealthKit

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .walking:
            return "Walking"
        case .swimming:
            return "Swimming"
        case .hiking:
            return "Hiking"
        case .yoga:
            return "Yoga"
        case .coreTraining:
            return "Core Training"
        case .mindAndBody:
            return "Mind and Body"
        case .soccer:
            return "Outdoor Soccer"
        case .traditionalStrengthTraining:
            return "Traditional Strength Training"
        case .functionalStrengthTraining:
            return "Functional Strength Training"
        default:
            return "Workout"
        }
    }
}

extension HKWorkout: Identifiable {
    public var id: UUID {
        uuid
    }
}
