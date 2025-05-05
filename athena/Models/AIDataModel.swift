import Foundation
import EventKit
import HealthKit

struct AIDataModel: Codable {
    let timestamp: Date
    let healthData: HealthData
    let calendarData: CalendarData
    
    struct HealthData: Codable {
        let steps: Double
        let heartRate: Double
        let activeEnergyBurned: Double
        let basalEnergyBurned: Double
        let distanceWalkingRunning: Double
        let flightsClimbed: Double
        let standHours: Double
        let exerciseMinutes: Double
        let sleepHours: Double
        let timeInDaylight: Double
        let bodyMass: Double
        let bodyFatPercentage: Double
        let bodyMassIndex: Double
        let leanBodyMass: Double
        let bodyTemperature: Double
        let bloodPressureSystolic: Double
        let bloodPressureDiastolic: Double
        let bloodOxygen: Double
        let respiratoryRate: Double
        let restingHeartRate: Double
        let walkingHeartRateAverage: Double
        let heartRateVariability: Double
        let vo2Max: Double
        let peakExpiratoryFlowRate: Double
        let forcedExpiratoryVolume1: Double
        let forcedVitalCapacity: Double
        let inhalerUsage: Double
        let insulinDelivery: Double
        let bloodGlucose: Double
        let dietaryEnergy: Double
        let dietaryProtein: Double
        let dietaryCarbohydrates: Double
        let dietaryFatTotal: Double
        let dietaryFatSaturated: Double
        let dietaryFatPolyunsaturated: Double
        let dietaryFatMonounsaturated: Double
        let dietaryCholesterol: Double
        let dietarySodium: Double
        let dietaryFiber: Double
        let dietarySugar: Double
        let dietaryVitaminA: Double
        let dietaryVitaminB6: Double
        let dietaryVitaminB12: Double
        let dietaryVitaminC: Double
        let dietaryVitaminD: Double
        let dietaryVitaminE: Double
        let dietaryVitaminK: Double
        let dietaryCalcium: Double
        let dietaryIron: Double
        let dietaryThiamin: Double
        let dietaryRiboflavin: Double
        let dietaryNiacin: Double
        let dietaryFolate: Double
        let dietaryBiotin: Double
        let dietaryPantothenicAcid: Double
        let dietaryPhosphorus: Double
        let dietaryIodine: Double
        let dietaryMagnesium: Double
        let dietaryZinc: Double
        let dietarySelenium: Double
        let dietaryCopper: Double
        let dietaryManganese: Double
        let dietaryChromium: Double
        let dietaryMolybdenum: Double
        let dietaryChloride: Double
        let dietaryPotassium: Double
        let dietaryCaffeine: Double
        let dietaryWater: Double
        let dietaryAlcohol: Double
        let dietaryEnergyConsumed: Double
        let dietaryEnergyBurned: Double
        let dietaryEnergyGoal: Double
        let dietaryEnergyRemaining: Double
        let dietaryEnergyPercentage: Double
        let dietaryProteinGoal: Double
        let dietaryProteinRemaining: Double
        let dietaryProteinPercentage: Double
        let dietaryCarbohydratesGoal: Double
        let dietaryCarbohydratesRemaining: Double
        let dietaryCarbohydratesPercentage: Double
        let dietaryFatTotalGoal: Double
        let dietaryFatTotalRemaining: Double
        let dietaryFatTotalPercentage: Double
        let dietaryFatSaturatedGoal: Double
        let dietaryFatSaturatedRemaining: Double
        let dietaryFatSaturatedPercentage: Double
        let dietaryFatPolyunsaturatedGoal: Double
        let dietaryFatPolyunsaturatedRemaining: Double
        let dietaryFatPolyunsaturatedPercentage: Double
        let dietaryFatMonounsaturatedGoal: Double
        let dietaryFatMonounsaturatedRemaining: Double
        let dietaryFatMonounsaturatedPercentage: Double
        let dietaryCholesterolGoal: Double
        let dietaryCholesterolRemaining: Double
        let dietaryCholesterolPercentage: Double
        let dietarySodiumGoal: Double
        let dietarySodiumRemaining: Double
        let dietarySodiumPercentage: Double
        let dietaryFiberGoal: Double
        let dietaryFiberRemaining: Double
        let dietaryFiberPercentage: Double
        let dietarySugarGoal: Double
        let dietarySugarRemaining: Double
        let dietarySugarPercentage: Double
        let dietaryVitaminAGoal: Double
        let dietaryVitaminARemaining: Double
        let dietaryVitaminAPercentage: Double
        let dietaryVitaminB6Goal: Double
        let dietaryVitaminB6Remaining: Double
        let dietaryVitaminB6Percentage: Double
        let dietaryVitaminB12Goal: Double
        let dietaryVitaminB12Remaining: Double
        let dietaryVitaminB12Percentage: Double
        let dietaryVitaminCGoal: Double
        let dietaryVitaminCRemaining: Double
        let dietaryVitaminCPercentage: Double
        let dietaryVitaminDGoal: Double
        let dietaryVitaminDRemaining: Double
        let dietaryVitaminDPercentage: Double
        let dietaryVitaminEGoal: Double
        let dietaryVitaminERemaining: Double
        let dietaryVitaminEPercentage: Double
        let dietaryVitaminKGoal: Double
        let dietaryVitaminKRemaining: Double
        let dietaryVitaminKPercentage: Double
        let dietaryCalciumGoal: Double
        let dietaryCalciumRemaining: Double
        let dietaryCalciumPercentage: Double
        let dietaryIronGoal: Double
        let dietaryIronRemaining: Double
        let dietaryIronPercentage: Double
        let dietaryThiaminGoal: Double
        let dietaryThiaminRemaining: Double
        let dietaryThiaminPercentage: Double
        let dietaryRiboflavinGoal: Double
        let dietaryRiboflavinRemaining: Double
        let dietaryRiboflavinPercentage: Double
        let dietaryNiacinGoal: Double
        let dietaryNiacinRemaining: Double
        let dietaryNiacinPercentage: Double
        let dietaryFolateGoal: Double
        let dietaryFolateRemaining: Double
        let dietaryFolatePercentage: Double
        let dietaryBiotinGoal: Double
        let dietaryBiotinRemaining: Double
        let dietaryBiotinPercentage: Double
        let dietaryPantothenicAcidGoal: Double
        let dietaryPantothenicAcidRemaining: Double
        let dietaryPantothenicAcidPercentage: Double
        let dietaryPhosphorusGoal: Double
        let dietaryPhosphorusRemaining: Double
        let dietaryPhosphorusPercentage: Double
        let dietaryIodineGoal: Double
        let dietaryIodineRemaining: Double
        let dietaryIodinePercentage: Double
        let dietaryMagnesiumGoal: Double
        let dietaryMagnesiumRemaining: Double
        let dietaryMagnesiumPercentage: Double
        let dietaryZincGoal: Double
        let dietaryZincRemaining: Double
        let dietaryZincPercentage: Double
        let dietarySeleniumGoal: Double
        let dietarySeleniumRemaining: Double
        let dietarySeleniumPercentage: Double
        let dietaryCopperGoal: Double
        let dietaryCopperRemaining: Double
        let dietaryCopperPercentage: Double
        let dietaryManganeseGoal: Double
        let dietaryManganeseRemaining: Double
        let dietaryManganesePercentage: Double
        let dietaryChromiumGoal: Double
        let dietaryChromiumRemaining: Double
        let dietaryChromiumPercentage: Double
        let dietaryMolybdenumGoal: Double
        let dietaryMolybdenumRemaining: Double
        let dietaryMolybdenumPercentage: Double
        let dietaryChlorideGoal: Double
        let dietaryChlorideRemaining: Double
        let dietaryChloridePercentage: Double
        let dietaryPotassiumGoal: Double
        let dietaryPotassiumRemaining: Double
        let dietaryPotassiumPercentage: Double
        let dietaryCaffeineGoal: Double
        let dietaryCaffeineRemaining: Double
        let dietaryCaffeinePercentage: Double
        let dietaryWaterGoal: Double
        let dietaryWaterRemaining: Double
        let dietaryWaterPercentage: Double
        let dietaryAlcoholGoal: Double
        let dietaryAlcoholRemaining: Double
        let dietaryAlcoholPercentage: Double
    }
    
    struct CalendarData: Codable {
        let todayEvents: [EventItem]
        let yesterdayEvents: [EventItem]
        let tomorrowEvents: [EventItem]
        let todayReminders: [ReminderItem]
        let yesterdayReminders: [ReminderItem]
        let tomorrowReminders: [ReminderItem]
    }
    
    struct EventItem: Codable {
        let title: String
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
        let location: String?
        let notes: String?
        
        init(from event: EKEvent) {
            self.title = event.title
            self.startDate = event.startDate
            self.endDate = event.endDate
            self.isAllDay = event.isAllDay
            self.location = event.location
            self.notes = event.notes
        }
    }
    
    struct ReminderItem: Codable {
        let title: String
        let dueDate: Date?
        let notes: String?
        let priority: Int
        let isCompleted: Bool
        
        init(from reminder: EKReminder) {
            self.title = reminder.title
            self.dueDate = reminder.dueDateComponents?.date
            self.notes = reminder.notes
            self.priority = reminder.priority
            self.isCompleted = reminder.isCompleted
        }
    }
} 