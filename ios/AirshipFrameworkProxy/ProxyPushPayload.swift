/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

public struct ProxyPushPayload: Sendable, Codable {
    public let notificationID: String?
    public let alert: String?
    public let title: String?
    public let extras: AirshipJSON

    enum CodingKeys: String, CodingKey {
        case alert
        case title
        case extras
        case notificationID = "notificationId"
    }

    init(request: UNNotificationRequest) throws {
        try self.init(
            userInfo: request.content.userInfo,
            notificationID: request.identifier
        )
    }

    init(notification: UNNotification) throws {
        try self.init(
            request: notification.request
        )
    }

    init(
        userInfo: [AnyHashable: Any],
        notificationID: String? = nil
    ) throws {

        self.notificationID = notificationID
        self.alert = Self.parseAlert(userInfo)
        self.title = Self.parseTitle(userInfo)

        var extras = userInfo
        extras["_"] = nil
        extras["aps"] = nil
        self.extras = try AirshipJSON.wrap(extras)
    }


    private static func parseAlert(_ userInfo: [AnyHashable: Any]) -> String? {
        if let aps = userInfo["aps"] as? [String : Any] {
            if let alert = aps["alert"] as? [String : Any] {
                if let body = alert["body"] as? String {
                    return body
                }
            } else if let alert = aps["alert"] as? String {
                return alert
            }
        }

        return nil
    }

    private static func parseTitle(_ userInfo: [AnyHashable: Any]) -> String? {
        if let aps = userInfo["aps"] as? [String : Any] {
            if let alert = aps["alert"] as? [String : Any] {
                if let title = alert["title"] as? String {
                    return title
                }
            }
        }

        return nil
    }
}
