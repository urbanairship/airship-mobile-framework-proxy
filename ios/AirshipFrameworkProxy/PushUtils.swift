/* Copyright Airship and Contributors */

import Foundation

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
}
