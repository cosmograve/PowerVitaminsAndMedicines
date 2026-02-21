import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let info = response.notification.request.content.userInfo
        let medIdString = info["medicationId"] as? String
        let scheduledTs = info["scheduledAt"] as? Double

        if let medIdString,
           let medId = UUID(uuidString: medIdString),
           let scheduledTs {
            let scheduledAt = Date(timeIntervalSince1970: scheduledTs)

            Task { @MainActor in
                switch response.actionIdentifier {
                case NotificationManager.actionTakenId:
                    AppStore.sharedIfYouHaveOne?.logDose(medicationId: medId, scheduledAt: scheduledAt, status: .taken)

                case NotificationManager.actionMissedId:
                    AppStore.sharedIfYouHaveOne?.logDose(medicationId: medId, scheduledAt: scheduledAt, status: .missed)

                default:
                    break
                }
                completionHandler()
            }
            return
        }

        completionHandler()
    }
}
