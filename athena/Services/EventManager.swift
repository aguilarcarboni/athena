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
        }
    }
    
    func fetchReminders() {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let reminders = reminders else { return }
            
            DispatchQueue.main.async {
                self?.reminders = reminders.filter { !$0.isCompleted }
            }
        }
    }
} 
