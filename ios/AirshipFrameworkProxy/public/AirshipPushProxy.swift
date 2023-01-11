/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit
import UserNotifications

public class AirshipPushProxy {

    private let proxyStore: ProxyStore
    private let pushProvider: () throws -> AirshipPush
    private var push: AirshipPush {
        get throws { try pushProvider() }
    }

    init(
        proxyStore: ProxyStore,
        pushProvider: @escaping () throws -> any AirshipPush
    ) {
        self.proxyStore = proxyStore
        self.pushProvider = pushProvider
    }


    public func setUserNotificationsEnabled(
        _ enabled: Bool
    ) throws -> Void {
        try self.push.userPushNotificationsEnabled = enabled
    }

    public func isUserNotificationsEnabled() throws -> Bool {
        return try self.push.userPushNotificationsEnabled
    }

    public func enableUserPushNotifications() async throws -> Bool {
        return try await self.push.enableUserNotifications()
    }

    public func getRegistrationToken() throws -> String {
        return try self.push.deviceToken ?? ""
    }

    public func setNotificationOptions(
        _ options:[Any]
    ) throws {
        let options = try UANotificationOptions.parse(options)
        try self.push.notificationOptions = options
    }

    public func setForegroundPresentationOptions(
        _ options:[Any]
    ) throws {
        let options = try UNNotificationPresentationOptions.parse(options)
        try self.push.defaultPresentationOptions = options
        self.proxyStore.foregroundPresentationOptions = options
    }

    public func getNotificationStatus() throws -> [String: Any] {
        let push = try self.push
        let isSystemEnabled = push.authorizedNotificationSettings != []

        let result: [String: Any] = [
            "airshipOptIn": push.isPushNotificationsOptedIn,
            "airshipEnabled": push.userPushNotificationsEnabled,
            "systemEnabled": isSystemEnabled,
            "ios": [
                "authorizedSettings": push.authorizedNotificationSettings.names,
                "authorizedStatus": try push.authorizationStatus.name
            ]
        ]

        return result
    }

    public func setAutobadgeEnabled(_ enabled: Bool) throws {
        try self.push.autobadgeEnabled = enabled
    }

    public func isAutobadgeEnabled() throws -> Bool {
        return try self.push.autobadgeEnabled
    }

    func setBadgeNumber(_ badgeNumber: Int) throws {
        try self.push.badgeNumber = badgeNumber
    }

    func getBadgeNumber() throws -> Int {
        return try self.push.badgeNumber
    }

    public func clearNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    public func clearNotification(_ identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [identifier]
        )
    }

    public func getActiveNotifications() async -> [[String: Any]] {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                let result = notifications.map { notification in
                    PushUtils.contentPayload(
                        notification.request.content.userInfo,
                        notificationID: notification.request.identifier
                    )
                }
                continuation.resume(returning: result)
            }
        }
    }
}


protocol AirshipPush: AnyObject {
    var userPushNotificationsEnabled: Bool { get set }
    var extendedPushNotificationPermissionEnabled: Bool { get set }
    var requestExplicitPermissionWhenEphemeral: Bool { get set }
    var deviceToken: String? { get }
    var notificationOptions: UANotificationOptions { get set }
    var authorizedNotificationSettings: UAAuthorizedNotificationSettings { get }
    var authorizationStatus: UAAuthorizationStatus { get }
    var userPromptedForNotifications: Bool { get }
    var defaultPresentationOptions: UNNotificationPresentationOptions { get set}
    var badgeNumber: Int { get set }
    var autobadgeEnabled: Bool { get set }
    var isPushNotificationsOptedIn: Bool { get}
    func enableUserNotifications() async -> Bool
}

extension Push: AirshipPush {
    func enableUserNotifications() async -> Bool {
        return await withCheckedContinuation { continuation in
            self.enableUserPushNotifications { result in
                continuation.resume(returning: result)
            }
        }
    }
}
