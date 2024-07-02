/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif

struct PushUtils {
    static func contentPayload(
        _ userInfo: [AnyHashable: Any],
        notificationID: String? = nil
    ) -> [String : Any] {

        var pushPayload: [String: Any] = [:]
        if let aps = userInfo["aps"] as? [String : Any] {
            if let alert = aps["alert"] as? [String : Any] {
                if let body = alert["body"] {
                    pushPayload["alert"] = body
                }
                if let title = alert["title"] {
                    pushPayload["title"] = title
                }
            } else if let alert = aps["alert"] as? String {
                pushPayload["alert"] = alert
            }
        }

        var extras = userInfo
        extras["_"] = nil
        extras["aps"] = nil

        pushPayload["extras"] = extras
        pushPayload["notificationId"] = notificationID

        return pushPayload
    }

    @MainActor
    static func findAction(_ notificationResponse: UNNotificationResponse) -> UNNotificationAction? {
        return Airship.push.combinedCategories.first(where: { (category) -> Bool in
            return category.identifier == notificationResponse.notification.request.content.categoryIdentifier
        })?.actions.first(where: { (action) -> Bool in
            return action.identifier == notificationResponse.actionIdentifier
        })
    }
}
