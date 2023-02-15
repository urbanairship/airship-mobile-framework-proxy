/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit
import UserNotifications

@objc
public class AirshipPushProxy: NSObject {

    public var presentationOptionOverrides: ((PresentationOptionsOverridesRequest) -> Void)?
    
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


    @objc
    public func setUserNotificationsEnabled(
        _ enabled: Bool
    ) throws -> Void {
        try self.push.userPushNotificationsEnabled = enabled
    }

    @objc(isUserNotificationsEnabledWithError:)
    public func _isUserNotificationsEnabled() throws -> NSNumber {
        return try NSNumber(value: self.push.userPushNotificationsEnabled)
    }

    public func isUserNotificationsEnabled() throws -> Bool {
        return try self.push.userPushNotificationsEnabled
    }

    @objc
    public func enableUserPushNotifications() async throws -> Bool {
        return try await self.push.enableUserNotifications()
    }

    @objc(getRegistrationTokenOrEmptyWithError:)
    public func _getRegistrationToken() throws -> String {
        return try getRegistrationToken() ?? ""
    }

    public func getRegistrationToken() throws -> String? {
        return try self.push.deviceToken
    }

    @objc
    public func setNotificationOptions(
        names:[String]
    ) throws {
        let options = try UANotificationOptions.parse(names)
        try self.push.notificationOptions = options
    }

    @objc
    public func setForegroundPresentationOptions(
        names:[String]
    ) throws {
        let options = try UNNotificationPresentationOptions.parse(names)
        try self.push.defaultPresentationOptions = options
        self.proxyStore.foregroundPresentationOptions = options
    }

    @objc
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

    @objc
    public func setAutobadgeEnabled(_ enabled: Bool) throws {
        try self.push.autobadgeEnabled = enabled
    }

    @objc(isAutobadgeEnabledWithError:)
    public func _isAutobadgeEnabled() throws -> NSNumber {
        return try NSNumber(value: self.isAutobadgeEnabled())
    }

    public func isAutobadgeEnabled() throws -> Bool {
        return try self.push.autobadgeEnabled
    }

    @objc
    public func setBadgeNumber(_ badgeNumber: Int) throws {
        try self.push.badgeNumber = badgeNumber
    }

    @objc(getBadgeNumberWithError:)
    public func _getBadgeNumber() throws -> NSNumber {
        return try NSNumber(value: self.getBadgeNumber())
    }

    public func getBadgeNumber() throws -> Int {
        return try self.push.badgeNumber
    }

    @objc
    public func clearNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    @objc
    public func clearNotification(_ identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [identifier]
        )
    }

    @objc
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
        
    @MainActor
    func presentationOptions(notification: UNNotification) async -> UNNotificationPresentationOptions? {
        guard let overrides = self.presentationOptionOverrides else {
            return nil
        }
        
        return await withCheckedContinuation{ continuation  in
            let payload = PushUtils.contentPayload(
                notification.request.content.userInfo,
                notificationID: notification.request.identifier
            )
            let request = PresentationOptionsOverridesRequest(pushPayload: payload) { options in
                continuation.resume(returning: options)
            }
            
            overrides(request)
        }
    }
}


public class PresentationOptionsOverridesRequest {
    private let onResult: (UNNotificationPresentationOptions?) -> Void
    public let pushPayload: [String: Any]
    init(pushPayload: [String: Any], onResult: @escaping (UNNotificationPresentationOptions?) -> Void) {
        self.pushPayload = pushPayload
        self.onResult = onResult
    }
    
    public func result(optionNames: [Any]?) {
        guard
            let names = optionNames,
            let options = try? UNNotificationPresentationOptions.parse(names)
        else {
            self.onResult(nil)
            return
        }
        
        self.onResult(options)
    }
    
    public func result(options: UNNotificationPresentationOptions?) {
        self.onResult(options)
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
