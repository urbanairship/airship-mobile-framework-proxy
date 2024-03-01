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

    public func getAuthorizedNotificationSettings() throws -> [String] {
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

    @MainActor
    public func setBadgeNumber(_ badgeNumber: Int) throws {
        try self.push.badgeNumber = badgeNumber
    }

    @MainActor
    public func getBadgeNumber() throws -> Int {
        return try self.push.badgeNumber
    }

    public func setQuietTime(_ settings: QuietTimeSettings) throws {
        try self.push.setQuietTimeStartHour(
            Int(settings.startHour),
            startMinute: Int(settings.startMinute),
            endHour: Int(settings.endHour),
            endMinute: Int(settings.endMinute)
        )
    }

    public func getQuietTime() throws -> QuietTimeSettings? {
        guard let dict = try self.push.quietTime else { return nil }
        return QuietTimeSettings(from: dict)
    }

    public func setQuietTimeEnabled(_ enabled: Bool) throws -> Void {
        try self.push.quietTimeEnabled = enabled
    }

    public func isQuietTimeEnabled() throws -> Bool {
        return try self.push.quietTimeEnabled
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
    func enableUserPushNotifications() async -> Bool
    var authorizationStatus: UAAuthorizationStatus { get }
    var userPushNotificationsEnabled: Bool { get set }
    var deviceToken: String? { get }
    var notificationOptions: UANotificationOptions { get set }
    var authorizedNotificationSettings: UAAuthorizedNotificationSettings { get }
    var defaultPresentationOptions: UNNotificationPresentationOptions { get set}
    @MainActor
    var badgeNumber: Int { get set }
    var autobadgeEnabled: Bool { get set }
    var notificationStatus: AirshipNotificationStatus { get async }
    var quietTime: [AnyHashable: Any]? { get }
    var quietTimeEnabled: Bool { get set }
    func setQuietTimeStartHour(
        _ startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    )
}

extension AirshipPush: AirshipPushProtocol {}

public struct QuietTimeSettings: Codable {
    let startHour: UInt
    let startMinute: UInt
    let endHour: UInt
    let endMinute: UInt

    public init(startHour: UInt, startMinute: UInt, endHour: UInt, endMinute: UInt) throws {
        guard startHour < 24, startMinute < 60 else {
            throw AirshipErrors.error("Invalid start time")
        }

        guard endHour < 24, endMinute < 60 else {
            throw AirshipErrors.error("Invalid end time")
        }

        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }

    init?(from dictionary: [AnyHashable: Any])  {
        guard
            let startTime = dictionary["start"] as? String,
            let endTime = dictionary["end"] as? String
        else {
            return nil
        }

        let startParts = startTime.components(separatedBy:":").compactMap { UInt($0) }
        let endParts = endTime.components(separatedBy:":").compactMap { UInt($0) }

        guard startParts.count == 2, endParts.count == 2 else { return nil }

        self.startHour = startParts[0]
        self.startMinute = startParts[1]
        self.endHour = endParts[0]
        self.endMinute = endParts[1]
    }
}



