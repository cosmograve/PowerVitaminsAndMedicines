import Foundation
import UserNotifications


final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    static let medicationCategoryId = "medication.category"

    static let actionTakenId = "medication.action.taken"
    static let actionMissedId = "medication.action.missed"


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


    func removePending(for medicationId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("med:\(medicationId.uuidString):") }

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func scheduleMedication(_ med: Medication, daysForward: Int = 30) {
        removePending(for: med.id)

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        let now = Date()
        let startDay = calendar.startOfDay(for: now)

        for offset in 0..<daysForward {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }

            guard med.frequency.shouldSchedule(on: day, calendar: calendar) else { continue }

            var comps = calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = med.intakeTime.hour
            comps.minute = med.intakeTime.minute

            guard let fireDate = calendar.date(from: comps) else { continue }

            if fireDate < now { continue }

            let content = UNMutableNotificationContent()
            content.title = "💊 Take \(med.name) (\(med.subtitle))"
            content.sound = .default
            content.categoryIdentifier = Self.medicationCategoryId

            content.userInfo = [
                "medicationId": med.id.uuidString,
                "scheduledAt": fireDate.timeIntervalSince1970
            ]

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let requestId = notificationId(medicationId: med.id, scheduledAt: fireDate)
            let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)

            center.add(request)
        }
    }

    func notificationId(medicationId: UUID, scheduledAt: Date) -> String {
        "med:\(medicationId.uuidString):\(Int(scheduledAt.timeIntervalSince1970))"
    }
}
