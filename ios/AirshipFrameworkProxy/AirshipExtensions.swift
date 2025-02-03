/* Copyright Airship and Contributors */

import Foundation
import UserNotifications

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
import AirshipMessageCenter
import AirshipPreferenceCenter
#endif


extension UNAuthorizationStatus {
    var name: String {
        get throws {
            switch (self) {
            case .authorized:
                return "authorized"
            case .denied:
                return "denied"
            case .provisional:
                return "provisional"
            case .ephemeral:
                return "ephemeral"
            case .notDetermined:
                return "not_determined"
            @unknown default:
                throw AirshipErrors.error(
                    "Unknown authorizationStatus \(self)"
                )
            }
        }
    }
}

extension AirshipAuthorizedNotificationSettings {
    private static let nameMap: [String: AirshipAuthorizedNotificationSettings] = [
        "alert": .alert,
        "badge": .badge,
        "sound": .sound,
        "announcement": .announcement,
        "car_play": .carPlay,
        "critical_alert": .criticalAlert,
        "notification_center": .notificationCenter,
        "scheduled_delivery": .scheduledDelivery,
        "time_sensitive": .timeSensitive,
        "lock_screen": .lockScreen
    ]

    var names: [String] {
        var names: [String] = []
        AirshipAuthorizedNotificationSettings.nameMap.forEach { key, value in
            if (self.contains(value)) {
                names.append(key)
            }
        }

        return names
    }
}

extension AirshipFeature {
    static let nameMap: [String: AirshipFeature] = [
        "push": .push,
        "contacts": .contacts,
        "message_center": .messageCenter,
        "analytics": .analytics,
        "tags_and_attributes": .tagsAndAttributes,
        "in_app_automation": .inAppAutomation,
        "feature_flags": .featureFlags,
        "all": .all,
        "none": []
    ]
    

    var names: [String] {
        var names: [String] = []
        if (self == .all) {
            return AirshipFeature.nameMap.keys.filter { key in
                key != "none" && key != "all"
            }
        }

        if (self == []) {
            return []
        }

        AirshipFeature.nameMap.forEach { key, value in
            if (value != [] && value != .all) {
                if (self.contains(value)) {
                    names.append(key)
                }
            }
        }

        return names
    }

    static func parse(_ names: [Any]) throws -> AirshipFeature {
        guard let names = names as? [String] else {
            throw AirshipErrors.error("Invalid feature \(names)")
        }

        var features: AirshipFeature = []

        try names.forEach { name in
            guard
                let feature = AirshipFeature.nameMap[name.lowercased()]
            else {
                throw AirshipErrors.error("Invalid feature \(name)")
            }
            features.update(with: feature)
        }

        return features
    }
}

extension UNAuthorizationOptions {

    static let nameMap: [String: UNAuthorizationOptions] = [
        "alert": .alert,
        "badge": .badge,
        "sound": .sound,
        "car_play": .carPlay,
        "critical_alert": .criticalAlert,
        "provides_app_notification_settings": .providesAppNotificationSettings,
        "provisional": .provisional
    ]

    static func parse(_ names: [Any]) throws -> UNAuthorizationOptions {
        guard let names = names as? [String] else {
            throw AirshipErrors.error("Invalid options \(names)")
        }

        var options: UNAuthorizationOptions = []

        try names.forEach { name in
            guard let option = UNAuthorizationOptions.nameMap[name.lowercased()] else {
                throw AirshipErrors.error("Invalid option \(name)")
            }
            options.update(with: option)
        }

        return options
    }

    var names: [String] {
        var names: [String] = []
        UNAuthorizationOptions.nameMap.forEach { key, value in
            if (self.contains(value)) {
                names.append(key)
            }
        }
        return names
    }
}

extension UNNotificationPresentationOptions {
    static let nameMap: [String: UNNotificationPresentationOptions] = {
        var map: [String: UNNotificationPresentationOptions] = [
            "badge": .badge,
            "sound": .sound,
        ]

        if #available(iOS 14.0, *) {
            map["list"] = .list
            map["banner"] = .banner
            map["alert"] = [.banner, .list]
        } else {
            map["list"] = .alert
            map["banner"] = .alert
            map["alert"] = .alert
        }

        return map
    }()

    static func parse(_ names: [Any]) throws -> UNNotificationPresentationOptions {
        guard let names = names as? [String] else {
            throw AirshipErrors.error("Invalid options \(names)")
        }

        var options: UNNotificationPresentationOptions = []

        try names.forEach { name in
            guard let option = UNNotificationPresentationOptions.nameMap[name.lowercased()] else {
                throw AirshipErrors.error("Invalid option \(name)")
            }
            options.update(with: option)
        }

        return options
    }

    var names: [String] {
        var names: [String] = []
        UNNotificationPresentationOptions.nameMap.forEach { key, value in
            if (self.contains(value)) {
                names.append(key)
            }
        }
        return names
    }
}
