import Foundation
import UserNotifications
import WorkoutKit

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    @Published var authorizationState: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        notificationCenter.delegate = self
        // Check current authorization state on init
        Task {
            await checkCurrentAuthorizationStatus()
        }
    }
    
    private func checkCurrentAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        DispatchQueue.main.async {
            self.authorizationState = settings.authorizationStatus
        }
    }
    
    func requestAuthorization() async -> UNAuthorizationStatus {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            // Update the state on the main thread as it's a @Published property
            DispatchQueue.main.async {
                self.authorizationState = granted ? .authorized : .denied
            }
            return granted ? .authorized : .denied
        } catch {
            // Update the state on the main thread
            DispatchQueue.main.async {
                self.authorizationState = .denied // Or handle as appropriate
            }
            return .denied // Or handle as appropriate
        }
    }

    func sendSummaryNotification() {
        Task {

            let content = UNMutableNotificationContent()
            content.title = "Summary has been generated"
            content.body = "Check it out in the app!"
            content.sound = .default
            
            // Schedule the notification for 5 seconds in the future
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger // Use the time interval trigger
            )
            
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to send summary notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedules a daily summary notification at 9:00 AM.
    func scheduleDailySummaryNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Athena"
        content.body = "Remember to generate your daily summary!"
        content.sound = .default

        // Configure the recurring date: 8:30 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 30

        // Create the trigger as a repeating event.
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        print("Scheduled daily summary notification at 8:30 AM")

        let request = UNNotificationRequest(
            identifier: "daily_summary_notification",
            content: content,
            trigger: trigger
        )

        // Remove any existing notification with the same identifier
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_summary_notification"])

        // Schedule the notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling daily summary notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification Management
    func getNotifications() async throws -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func removeNotifications() async throws {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
