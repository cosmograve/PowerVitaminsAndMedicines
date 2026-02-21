


import Foundation
import UserNotifications

// MARK: - NotificationManager
// Responsibilities:
// 1) Request notification permission.
// 2) Register action categories (Taken / Missed).
// 3) Schedule notifications for medications.
// 4) Provide stable identifiers so we can map notification -> medication + scheduled time.

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    // Category id used by all medication notifications.
    static let medicationCategoryId = "medication.category"

    // Action ids.
    static let actionTakenId = "medication.action.taken"
    static let actionMissedId = "medication.action.missed"

    // MARK: - Setup

    /// Call once at app start.
    func configureCategories() {
        let taken = UNNotificationAction(
            identifier: Self.actionTakenId,
            title: "Taken",
            options: [.authenticationRequired]
        )

        let missed = UNNotificationAction(
            identifier: Self.actionMissedId,
            title: "Missed",
            options: [.destructive, .authenticationRequired]
        )

        let category = UNNotificationCategory(
            identifier: Self.medicationCategoryId,
            actions: [taken, missed],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Ask user permission (recommended at app start).
    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                return granted
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    // MARK: - Scheduling

    /// Remove all pending notifications for a medication (before re-scheduling).
    func removePending(for medicationId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("med:\(medicationId.uuidString):") }

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// Schedule notifications for next N days (rolling window).
    /// MVP: 30 days forward. On app launch you can refresh window.
    func scheduleMedication(_ med: Medication, daysForward: Int = 30) {
        // First clear previous schedule to avoid duplicates.
        removePending(for: med.id)

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        let now = Date()
        let startDay = calendar.startOfDay(for: now)

        for offset in 0..<daysForward {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }

            // Check if medication should happen on that day per frequency.
            guard med.frequency.shouldSchedule(on: day, calendar: calendar) else { continue }

            // Build scheduled date with med intake time (hour/minute).
            var comps = calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = med.intakeTime.hour
            comps.minute = med.intakeTime.minute

            guard let fireDate = calendar.date(from: comps) else { continue }

            // Don't schedule in the past.
            if fireDate < now { continue }

            let content = UNMutableNotificationContent()
            content.title = "💊 Take \(med.name) (\(med.subtitle))"
            content.sound = .default
            content.categoryIdentifier = Self.medicationCategoryId

            // Put routing info in userInfo.
            content.userInfo = [
                "medicationId": med.id.uuidString,
                "scheduledAt": fireDate.timeIntervalSince1970
            ]

            // Calendar trigger
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            // Stable identifier so we can remove/update later.
            let requestId = notificationId(medicationId: med.id, scheduledAt: fireDate)
            let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)

            center.add(request)
        }
    }

    /// Identifier format: med:<uuid>:<timestamp>
    func notificationId(medicationId: UUID, scheduledAt: Date) -> String {
        "med:\(medicationId.uuidString):\(Int(scheduledAt.timeIntervalSince1970))"
    }
}
