/* Copyright Airship and Contributors */

import Foundation
import UserNotifications

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

struct PushUtils {
    @MainActor
    static func findAction(_ notificationResponse: UNNotificationResponse) -> UNNotificationAction? {
        return Airship.push.combinedCategories.first(where: { (category) -> Bool in
            return category.identifier == notificationResponse.notification.request.content.categoryIdentifier
        })?.actions.first(where: { (action) -> Bool in
            return action.identifier == notificationResponse.actionIdentifier
        })
    }

    static func deviceTokenString(_ token: Data) -> String {
        [UInt8](token).reduce(into: "") { $0.append(String(format: "%02x", $1)) }
    }
}
