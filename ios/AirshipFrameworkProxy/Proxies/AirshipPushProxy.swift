/* Copyright Urban Airship and Contributors */

import Foundation
import AirshipKit
import UserNotifications

public class AirshipPushProxy {

    public var presentationOptionOverrides: ((PresentationOptionsOverridesRequest) -> Void)?
    
    private let proxyStore: ProxyStore
    private let pushProvider: () throws -> AirshipPushProtocol
    private var push: AirshipPushProtocol {
        get throws { try pushProvider() }
    }

    init(
        proxyStore: ProxyStore,
        pushProvider: @escaping () throws -> AirshipPushProtocol
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
        return try await self.push.enableUserPushNotifications()
    }

    public func getRegistrationToken() throws -> String? {
        return try self.push.deviceToken
    }

    public func setNotificationOptions(
        names:[String]
    ) throws {
        let options = try UANotificationOptions.parse(names)
        try self.push.notificationOptions = options
    }

    public func setForegroundPresentationOptions(
        names:[String]
    ) throws {
        let options = try UNNotificationPresentationOptions.parse(names)
        try self.push.defaultPresentationOptions = options
        self.proxyStore.foregroundPresentationOptions = options
    }

    public func getNotificationStatus() async throws -> [String: Any] {
        let status = try await self.push.notificationStatus
        return NotificationStatus(airshipStatus: status).toMap
    }

    public func getAuthorizedNotificationOptions() throws -> [String] {
        return try self.push.authorizedNotificationSettings.names
    }

    public func getAuthroizedNotificationStatus() throws -> String {
        return try self.push.authorizationStatus.name
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

    public func setBadgeNumber(_ badgeNumber: Int) throws {
        try self.push.badgeNumber = badgeNumber
    }

    public func getBadgeNumber() async throws -> Int {
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


protocol AirshipPushProtocol: AnyObject {
    var userPushNotificationsEnabled: Bool { get set }
    var deviceToken: String? { get }
    var notificationOptions: UANotificationOptions { get set }
    var authorizedNotificationSettings: UAAuthorizedNotificationSettings { get }
    var authorizationStatus: UAAuthorizationStatus { get }
    var userPromptedForNotifications: Bool { get }
    var defaultPresentationOptions: UNNotificationPresentationOptions { get set}
    var badgeNumber: Int { get set }
    var autobadgeEnabled: Bool { get set }
    var isPushNotificationsOptedIn: Bool { get}
    func enableUserPushNotifications() async -> Bool
    var notificationStatus: AirshipNotificationStatus { get async }

}


extension AirshipPush : AirshipPushProtocol {}
