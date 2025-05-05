import Foundation
import EventKit

struct EventItem: Identifiable {
    let id: String
    let event: EKEvent
}

class EventManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var events: [EventItem] = []
    @Published var reminders: [EKReminder] = []
    @Published var isAuthorized = false
    
    // AI Data
    @Published var aiData: AIDataModel?
    
    func requestAuthorization() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.fetchEvents()
                }
            }
        }
        
        eventStore.requestAccess(to: .reminder) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.fetchReminders()
                }
            }
        }
    }
    
    func fetchEvents() {
        let calendar = Calendar.current
        let now = Date()
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        // Extend the end date to the end of tomorrow
        let endOfTomorrow = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: now))!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfYesterday, end: endOfTomorrow, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // Create unique identifiers and sort events by date
        let eventItems = events.map { event -> EventItem in
            let uniqueId = "\(event.eventIdentifier)_\(event.startDate.timeIntervalSince1970)"
            return EventItem(id: uniqueId, event: event)
        }.sorted { $0.event.startDate < $1.event.startDate }
        
        DispatchQueue.main.async {
            self.events = eventItems
            self.updateAIData()
        }
    }
    
    func fetchReminders() {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let reminders = reminders else { return }
            
            DispatchQueue.main.async {
                self?.reminders = reminders.filter { !$0.isCompleted }
                self?.updateAIData()
            }
        }
    }
    
    private func updateAIData() {
        let calendar = Calendar.current
        let now = Date()
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        // Add start and end of tomorrow
        let startOfTomorrow = endOfToday
        let endOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfTomorrow)!
        
        // Filter events for yesterday and today
        let yesterdayEvents = events.filter { event in
            let eventDate = calendar.startOfDay(for: event.event.startDate)
            return eventDate == startOfYesterday
        }.map { AIDataModel.EventItem(from: $0.event) }
        
        let todayEvents = events.filter { event in
            let eventDate = calendar.startOfDay(for: event.event.startDate)
            return eventDate == startOfToday
        }.map { AIDataModel.EventItem(from: $0.event) }
        
        // Filter events for tomorrow
        let tomorrowEvents = events.filter { event in
            let eventDate = calendar.startOfDay(for: event.event.startDate)
            return eventDate == startOfTomorrow
        }.map { AIDataModel.EventItem(from: $0.event) }
        
        // Filter reminders for yesterday and today
        let yesterdayReminders = reminders.filter { reminder in
            guard let dueDate = reminder.dueDateComponents?.date else { return false }
            let reminderDate = calendar.startOfDay(for: dueDate)
            return reminderDate == startOfYesterday
        }.map { AIDataModel.ReminderItem(from: $0) }
        
        let todayReminders = reminders.filter { reminder in
            guard let dueDate = reminder.dueDateComponents?.date else { return false }
            let reminderDate = calendar.startOfDay(for: dueDate)
            return reminderDate == startOfToday
        }.map { AIDataModel.ReminderItem(from: $0) }
        
        // Filter reminders for tomorrow
        let tomorrowReminders = reminders.filter { reminder in
            guard let dueDate = reminder.dueDateComponents?.date else { return false }
            let reminderDate = calendar.startOfDay(for: dueDate)
            return reminderDate == startOfTomorrow
        }.map { AIDataModel.ReminderItem(from: $0) }
        
        // Create AI data model
        let calendarData = AIDataModel.CalendarData(
            todayEvents: todayEvents,
            yesterdayEvents: yesterdayEvents,
            tomorrowEvents: tomorrowEvents,
            todayReminders: todayReminders,
            yesterdayReminders: yesterdayReminders,
            tomorrowReminders: tomorrowReminders
        )
        
        // Note: Health data will be added by HealthManager
        self.aiData = AIDataModel(
            timestamp: now,
            healthData: AIDataModel.HealthData(
                steps: 0,
                heartRate: 0,
                activeEnergyBurned: 0,
                basalEnergyBurned: 0,
                distanceWalkingRunning: 0,
                flightsClimbed: 0,
                standHours: 0,
                exerciseMinutes: 0,
                sleepHours: 0,
                timeInDaylight: 0,
                bodyMass: 0,
                bodyFatPercentage: 0,
                bodyMassIndex: 0,
                leanBodyMass: 0,
                bodyTemperature: 0,
                bloodPressureSystolic: 0,
                bloodPressureDiastolic: 0,
                bloodOxygen: 0,
                respiratoryRate: 0,
                restingHeartRate: 0,
                walkingHeartRateAverage: 0,
                heartRateVariability: 0,
                vo2Max: 0,
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
            ),
            calendarData: calendarData
        )
    }
} 
