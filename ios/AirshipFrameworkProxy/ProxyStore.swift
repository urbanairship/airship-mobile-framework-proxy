/* Copyright Airship and Contributors */

import Foundation
import AirshipKit

public class ProxyStore {

    static let shared: ProxyStore = ProxyStore()

    private let defaults: UserDefaults = UserDefaults(
        suiteName: "airship-framework-proxy"
    )!

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let configKey = "config"
    private let foregroundPresentationOptionsKey = "foregroundPresentationOptions"
    private let autoDisplayMessageCenterKey = "autoDisplayMessageCenter"
    private let lastNotificationStatusKey = "lastNotificationStatus"

    public var defaultAutoDisplayMessageCenter: Bool = true
    public var defaultPresentationOptions: UNNotificationPresentationOptions = []


    public var config: ProxyConfig? {
        get {
            return readCodable(configKey)
        }
        set {
            writeCodable(newValue, forKey: configKey)
        }
    }

    public var foregroundPresentationOptions: UNNotificationPresentationOptions {
        get {
            guard 
                let value: UInt = readValue(foregroundPresentationOptionsKey)
            else {

                return defaultPresentationOptions
            }

            return UNNotificationPresentationOptions(rawValue: value)
        }

        set {
            writeValue(
                newValue.rawValue,
                forKey: foregroundPresentationOptionsKey
            )
        }
    }

    public var autoDisplayMessageCenter: Bool {
        get {
            return readValue(autoDisplayMessageCenterKey) ?? defaultAutoDisplayMessageCenter
        }

        set {
            writeValue(
                newValue,
                forKey: autoDisplayMessageCenterKey
            )
        }
    }

    public var lastNotificationStatus: NotificationStatus? {
        get {
            return readCodable(lastNotificationStatusKey)
        }

        set {
            writeCodable(
                newValue,
                forKey: lastNotificationStatusKey
            )
        }
    }

    private func preferenceCenterKey(
        _ preferenceCenterID: String
    ) -> String {
        return "com.urbanairship.react.preference_\(preferenceCenterID)_autolaunch"
    }


    public func setAutoLaunchPreferenceCenter(
        _ preferenceCenterID: String,
        autoLaunch: Bool
    ) {
        writeValue(
            autoLaunch,
            forKey: preferenceCenterKey(preferenceCenterID)
        )
    }

    func shouldAutoLaunchPreferenceCenter(
        _ preferenceCenterID: String
    ) -> Bool {
        let autoLaunch: Bool? = readValue(
            preferenceCenterKey(preferenceCenterID)
        )
        return autoLaunch ?? true
    }

    private func readCodable<T: Codable>(_ key: String) -> T? {
        guard let data: Data = readValue(key) else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            AirshipLogger.error("Failed to decode value for key \(key): \(error)")
            return nil
        }
    }

    private func readValue<T>(_ key: String) -> T? {
        let result = self.defaults.object(forKey: key)
        return result as? T
    }

    private func writeCodable<T: Codable>(
        _ codable: T?,
        forKey key: String
    ) {
        guard let codable = codable else {
            writeValue(nil, forKey: key)
            return
        }

        do {
            let data = try encoder.encode(codable)
            writeValue(data, forKey: key)
        } catch {
            AirshipLogger.error("Failed to write codable for key \(key): \(error)")
        }
    }

    private func writeValue(_ value: Any?, forKey key: String) {
        if let value = value {
            self.defaults.set(value, forKey: key)
        } else {
            self.defaults.removeObject(forKey: key)
        }
    }

}
