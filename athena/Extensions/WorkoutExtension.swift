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
        case .crossTraining:
            return "Cross Training"
        case .mixedCardio:
            return "Mixed Cardio"
        case .highIntensityIntervalTraining:
            return "High Intensity Interval Training"
        case .jumpRope:
            return "Jump Rope"
        default:
            return "Workout"
        }
    }
}

extension HKWorkoutActivityType {
    var icon: String {
        switch self {
        case .archery: return "figure.archery"
        case .bowling: return "figure.bowling"
        case .fencing: return "figure.fencing"
        case .gymnastics: return "figure.gymnastics"
        case .trackAndField: return "figure.track.and.field"
        case .americanFootball: return "figure.american.football"
        case .australianFootball: return "figure.australian.football"
        case .baseball: return "figure.baseball"
        case .basketball: return "figure.basketball"
        case .cricket: return "figure.cricket"
        case .discSports: return "figure.disc.sports"
        case .handball: return "figure.handball"
        case .hockey: return "figure.hockey"
        case .lacrosse: return "figure.lacrosse"
        case .rugby: return "figure.rugby"
        case .soccer: return "figure.outdoor.soccer"
        case .softball: return "figure.softball"
        case .volleyball: return "figure.volleyball"
        case .preparationAndRecovery: return "figure.cooldown"
        case .flexibility: return "figure.flexibility"
        case .cooldown: return "figure.cooldown"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .wheelchairWalkPace: return "figure.roll"
        case .wheelchairRunPace: return "figure.roll.runningpace"
        case .cycling: return "figure.outdoor.cycle"
        case .handCycling: return "figure.hand.cycling"
        case .coreTraining: return "figure.core.training"
        case .elliptical: return "figure.elliptical"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .crossTraining: return "figure.cross.training"
        case .mixedCardio: return "figure.mixed.cardio"
        case .highIntensityIntervalTraining: return "figure.highintensity.intervaltraining"
        case .jumpRope: return "figure.jumprope"
        case .stairClimbing: return "figure.stair.stepper"
        case .stairs: return "figure.stairs"
        case .stepTraining: return "figure.step.training"
        case .fitnessGaming: return "gamecontroller"
        case .barre: return "figure.barre"
        case .cardioDance: return "figure.dance"
        case .socialDance: return "figure.socialdance"
        case .yoga: return "figure.yoga"
        case .mindAndBody: return "figure.mind.and.body"
        case .pilates: return "figure.pilates"
        case .badminton: return "figure.badminton"
        case .pickleball: return "figure.pickleball"
        case .racquetball: return "figure.racquetball"
        case .squash: return "figure.squash"
        case .tableTennis: return "figure.table.tennis"
        case .tennis: return "figure.tennis"
        case .climbing: return "figure.climbing"
        case .equestrianSports: return "figure.equestrian.sports"
        case .fishing: return "figure.fishing"
        case .golf: return "figure.golf"
        case .hiking: return "figure.hiking"
        case .hunting: return "figure.hunting"
        case .play: return "figure.play"
        case .crossCountrySkiing: return "figure.skiing.crosscountry"
        case .curling: return "figure.curling"
        case .downhillSkiing: return "figure.skiing.downhill"
        case .snowSports: return "figure.snowboarding"
        case .snowboarding: return "figure.snowboarding"
        case .skatingSports: return "figure.ice.skating"
        case .paddleSports: return "figure.surfing"
        case .rowing: return "figure.indoor.rowing"
        case .sailing: return "figure.sailing"
        case .surfingSports: return "figure.surfing"
        case .swimming: return "figure.pool.swim"
        case .waterFitness: return "figure.water.fitness"
        case .waterPolo: return "figure.waterpolo"
        case .waterSports: return "figure.water.fitness"
        case .boxing: return "figure.boxing"
        case .kickboxing: return "figure.kickboxing"
        case .martialArts: return "figure.martial.arts"
        case .taiChi: return "figure.taichi"
        case .wrestling: return "figure.wrestling"
        case .swimBikeRun: return "figure.cross.training"
        case .transition: return "arrow.triangle.2.circlepath"
        case .underwaterDiving: return "figure.pool.swim"
        case .other: return "figure.walk"
        default: return "figure.walk"
        }
    }
}

extension HKWorkout: @retroactive Identifiable {
    public var id: UUID {
        uuid
    }
}
