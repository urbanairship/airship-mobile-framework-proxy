/* Copyright Urban Airship and Contributors */

import Foundation
public import UserNotifications

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
#endif

public final class AirshipPushProxy: Sendable {

    @MainActor
    public var presentationOptionOverrides: ((PresentationOptionsOverridesRequest) -> Void)?

    private let proxyStore: ProxyStore
    private let pushProvider: @Sendable () throws -> any AirshipPush
    private var push: any AirshipPush {
        get throws { try pushProvider() }
    }

    init(
        proxyStore: ProxyStore,
        pushProvider: @Sendable @escaping () throws -> any AirshipPush
    ) {
        self.proxyStore = proxyStore
        self.pushProvider = pushProvider
    }

    public func setUserNotificationsEnabled(
        _ enabled: Bool
    ) throws -> Void {
        AirshipLogger.trace("setUserNotificationsEnabled called, enabled=\(enabled)")
        try self.push.userPushNotificationsEnabled = enabled
    }

    public func isUserNotificationsEnabled() throws -> Bool {
        AirshipLogger.trace("isUserNotificationsEnabled called")
        return try self.push.userPushNotificationsEnabled
    }

    public func enableUserPushNotifications(
        args: EnableUserPushNotificationsArgs? = nil
    ) async throws -> Bool {
        AirshipLogger.trace("enableUserPushNotifications called")
        return try await self.push.enableUserPushNotifications(
            fallback: args?.fallback ?? .none
        )
    }

    @MainActor
    public func getRegistrationToken() throws -> String? {
        AirshipLogger.trace("getRegistrationToken called")
        return try self.push.deviceToken
    }

    @MainActor
    public func setNotificationOptions(
        names:[String]
    ) throws {
        AirshipLogger.trace("setNotificationOptions called")
        let options = try UNAuthorizationOptions.parse(names)
        try self.push.notificationOptions = options
    }

    @MainActor
    public func setForegroundPresentationOptions(
        names: [String]
    ) throws {
        AirshipLogger.trace("setForegroundPresentationOptions called")
        let options = try UNNotificationPresentationOptions.parse(names)
        try self.push.defaultPresentationOptions = options
        self.proxyStore.foregroundPresentationOptions = options
    }

    public var notificationStatus: NotificationStatus {
        get async throws {
            let status = try await self.push.notificationStatus
            return NotificationStatus(airshipStatus: status)
        }
    }

    public func getAuthorizedNotificationSettings() throws -> [String] {
        AirshipLogger.trace("getAuthorizedNotificationSettings called")
        return try self.push.authorizedNotificationSettings.names
    }

    public func getAuthroizedNotificationStatus() throws -> String {
        AirshipLogger.trace("getAuthroizedNotificationStatus called")
        return try self.push.authorizationStatus.name
    }

    @objc
    public func setAutobadgeEnabled(_ enabled: Bool) throws {
        AirshipLogger.trace("setAutobadgeEnabled called, enabled=\(enabled)")
        try self.push.autobadgeEnabled = enabled
    }

    @objc(isAutobadgeEnabledWithError:)
    public func _isAutobadgeEnabled() throws -> NSNumber {
        return try NSNumber(value: self.isAutobadgeEnabled())
    }

    public func isAutobadgeEnabled() throws -> Bool {
        AirshipLogger.trace("isAutobadgeEnabled called")
        return try self.push.autobadgeEnabled
    }

    @MainActor
    public func setBadgeNumber(_ badgeNumber: Int) async throws {
        AirshipLogger.trace("setBadgeNumber called, badgeNumber=\(badgeNumber)")
        try await self.push.setBadgeNumber(badgeNumber)
    }

    @MainActor
    public func getBadgeNumber() throws -> Int {
        AirshipLogger.trace("getBadgeNumber called")
        return try self.push.badgeNumber
    }

    public func setQuietTime(_ settings: ProxyQuietTimeSettings) throws {
        AirshipLogger.trace("setQuietTime called")
        try self.push.quietTime = QuietTimeSettings(
            startHour: settings.startHour,
            startMinute: settings.startMinute,
            endHour: settings.endHour,
            endMinute: settings.endMinute
        )
    }

    public func getQuietTime() throws -> ProxyQuietTimeSettings? {
        AirshipLogger.trace("getQuietTime called")
        guard let settings = try self.push.quietTime else { return nil }
        return settings.proxySettings
    }

    public func setQuietTimeEnabled(_ enabled: Bool) throws -> Void {
        AirshipLogger.trace("setQuietTimeEnabled called, enabled=\(enabled)")
        try self.push.quietTimeEnabled = enabled
    }

    public func isQuietTimeEnabled() throws -> Bool {
        AirshipLogger.trace("isQuietTimeEnabled called")
        return try self.push.quietTimeEnabled
    }

    @objc
    public func clearNotifications() {
        AirshipLogger.trace("clearNotifications called")
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    @objc
    public func clearNotification(_ identifier: String) {
        AirshipLogger.trace("clearNotification called, identifier=\(identifier)")
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [identifier]
        )
    }

    public func getActiveNotifications() async throws -> [ProxyPushPayload] {
        AirshipLogger.trace("getActiveNotifications called")
        let notifications = await UNUserNotificationCenter.current().deliveredNotifications()
        return try notifications.map { notification in
            try ProxyPushPayload(notification: notification)
        }
    }
        
    @MainActor
    func presentationOptions(notification: UNNotification) async throws -> UNNotificationPresentationOptions? {
        guard let overrides = self.presentationOptionOverrides else {
            return nil
        }

        let payload = try ProxyPushPayload(
            notification: notification
        )

        return await withCheckedContinuation{ continuation  in
            let request = PresentationOptionsOverridesRequest(pushPayload: payload) { options in
                continuation.resume(returning: options)
            }
            
            overrides(request)
        }
    }
}

public final class PresentationOptionsOverridesRequest: Sendable {
    private let onResult: @Sendable (UNNotificationPresentationOptions?) -> Void
    public let pushPayload: ProxyPushPayload
    init(pushPayload: ProxyPushPayload, onResult: @Sendable @escaping (UNNotificationPresentationOptions?) -> Void) {
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

public struct ProxyQuietTimeSettings: Codable {
    let startHour: UInt
    let startMinute: UInt
    let endHour: UInt
    let endMinute: UInt
}

extension QuietTimeSettings {
    var proxySettings: ProxyQuietTimeSettings {
        return ProxyQuietTimeSettings(
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute
        )
    }
}


public struct EnableUserPushNotificationsArgs: Decodable, Sendable {
    public let fallback: PromptPermissionFallback?

    enum CodingKeys: String, CodingKey {
        case fallback
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallbackString = try container.decodeIfPresent(String.self, forKey: .fallback)
        self.fallback = if (fallbackString?.caseInsensitiveCompare("systemSettings") == .orderedSame) {
            PromptPermissionFallback.systemSettings
        } else {
            nil
        }
    }
}
