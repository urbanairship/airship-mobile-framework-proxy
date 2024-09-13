import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif


public struct NotificationStatus: Sendable, Equatable, Codable {

    init(airshipStatus: AirshipNotificationStatus) {
        self.isUserNotificationsEnabled = airshipStatus.isUserNotificationsEnabled
        self.areNotificationsAllowed = airshipStatus.areNotificationsAllowed
        self.isPushPrivacyFeatureEnabled = airshipStatus.isPushPrivacyFeatureEnabled
        self.isPushTokenRegistered = airshipStatus.isPushTokenRegistered
        self.isUserOptedIn = airshipStatus.isUserOptedIn
        self.isOptedIn = airshipStatus.isOptedIn
        self.notificationPermissionStatus = airshipStatus.displayNotificationStatus.stringValue
    }

    public let isUserNotificationsEnabled: Bool
    public let areNotificationsAllowed: Bool
    public let isPushPrivacyFeatureEnabled: Bool
    public let isPushTokenRegistered: Bool
    public let isUserOptedIn: Bool
    public let isOptedIn: Bool
    public let notificationPermissionStatus: String?

    enum CodingKeys: String, CodingKey {
        case isUserNotificationsEnabled
        case areNotificationsAllowed
        case isPushPrivacyFeatureEnabled
        case isPushTokenRegistered
        case isUserOptedIn
        case isOptedIn
        case notificationPermissionStatus
    }

    var toMap: [String: Any] {
        var map: [String: Any] = [
            "isUserNotificationsEnabled": self.isUserNotificationsEnabled,
            "areNotificationsAllowed": self.areNotificationsAllowed,
            "isPushPrivacyFeatureEnabled": self.isPushPrivacyFeatureEnabled,
            "isPushTokenRegistered": self.isPushTokenRegistered,
            "isOptedIn": self.isOptedIn,
            "isUserOptedIn": self.isUserOptedIn
        ]

        if let notificationPermissionStatus {
            map["notificationPermissionStatus"] = notificationPermissionStatus
        }

        return map
    }

}

