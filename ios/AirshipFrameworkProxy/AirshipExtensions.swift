/* Copyright Airship and Contributors */

import Foundation
import AirshipKit

extension UAAuthorizationStatus {
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

extension UAAuthorizedNotificationSettings {
    private static let nameMap: [String: UAAuthorizedNotificationSettings] = [
        "alert": UAAuthorizedNotificationSettings.alert,
        "badge": UAAuthorizedNotificationSettings.badge,
        "sound": UAAuthorizedNotificationSettings.sound,
        "announcement": UAAuthorizedNotificationSettings.announcement,
        "car_play": UAAuthorizedNotificationSettings.carPlay,
        "critical_alert": UAAuthorizedNotificationSettings.criticalAlert,
        "notification_center": UAAuthorizedNotificationSettings.notificationCenter,
        "scheduled_delivery": UAAuthorizedNotificationSettings.scheduledDelivery,
        "time_sensitive": UAAuthorizedNotificationSettings.timeSensitive,
        "lock_screen": UAAuthorizedNotificationSettings.lockScreen
    ]

    var names: [String] {
        var names: [String] = []
        UAAuthorizedNotificationSettings.nameMap.forEach { key, value in
            if (self.contains(value)) {
                names.append(key)
            }
        }

        return names
    }
}

extension UANotificationOptions {

    static let nameMap: [String: UANotificationOptions] = [
        "alert": .alert,
        "badge": .badge,
        "sound": .sound,
        "car_play": .carPlay,
        "critical_alert": .criticalAlert,
        "provides_app_notification_settings": .providesAppNotificationSettings,
        "provisional": .provisional
    ]

    static func parse(_ names: [Any]) throws -> UANotificationOptions {
        guard let names = names as? [String] else {
            throw AirshipErrors.error("Invalid options \(names)")
        }

        var options: UANotificationOptions = []

        try names.forEach { name in
            guard let option = UANotificationOptions.nameMap[name.lowercased()] else {
                throw AirshipErrors.error("Invalid option \(name)")
            }
            options.update(with: option)
        }

        return options
    }

    var names: [String] {
        var names: [String] = []
        UANotificationOptions.nameMap.forEach { key, value in
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
