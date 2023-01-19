import Foundation
import UIKit
import AirshipKit

public enum AirshipProxyError: Error {
    case takeOffNotCalled
    case invalidConfig(String)
}

@objc
public class AirshipProxy: NSObject {
    private let proxyStore: ProxyStore
    private let launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    private let onAirshipReady: (() -> Void)?
    private let airshipDelegate: AirshipDelegate

    @objc
    public let locale: AirshipLocaleProxy
    @objc
    public let push: AirshipPushProxy
    @objc
    public let channel: AirshipChannelProxy
    @objc
    public let messageCenter: AirshipMessageCenterProxy
    @objc
    public let preferenceCenter: AirshipPreferenceCenterProxy
    @objc
    public let inApp: AirshipInAppProxy
    @objc
    public let contact: AirshipContactProxy
    @objc
    public let analytics: AirshipAnalyticsProxy
    @objc
    public let action: AirshipActionProxy
    @objc
    public let privacyManager: AirshipPrivacyManagerProxy


    public convenience init(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        onAirshipReady: (() -> Void)? = nil
    ) {
        self.init(
            launchOptions: launchOptions,
            proxyStore: ProxyStore(),
            onAirshipReady: onAirshipReady
        )
    }

    init(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        proxyStore: ProxyStore,
        onAirshipReady: (() -> Void)? = nil
    ) {
        self.launchOptions = launchOptions
        self.onAirshipReady = onAirshipReady
        self.proxyStore = proxyStore
        self.airshipDelegate = AirshipDelegate(
            proxyStore: proxyStore
        )
        self.locale = AirshipLocaleProxy {
            try AirshipProxy.ensureAirshipReady()
            return Airship.shared.localeManager
        }
        
        self.push = AirshipPushProxy(proxyStore: proxyStore) {
            try AirshipProxy.ensureAirshipReady()
            return Airship.push
        }
        
        self.channel = AirshipChannelProxy {
            try AirshipProxy.ensureAirshipReady()
            return Airship.channel
        }

        self.messageCenter = AirshipMessageCenterProxy(
            proxyStore: proxyStore
        ) {
            try AirshipProxy.ensureAirshipReady()
            return MessageCenter.shared
        }

        self.preferenceCenter = AirshipPreferenceCenterProxy(
            proxyStore: proxyStore
        ) {
            try AirshipProxy.ensureAirshipReady()
            return PreferenceCenter.shared
        }
        self.inApp = AirshipInAppProxy {
            try AirshipProxy.ensureAirshipReady()
            return InAppAutomation.shared
        }

        self.contact = AirshipContactProxy {
            try AirshipProxy.ensureAirshipReady()
            return Airship.contact
        }

        self.analytics = AirshipAnalyticsProxy {
            try AirshipProxy.ensureAirshipReady()
            return Airship.analytics
        }

        self.action = AirshipActionProxy {
            try AirshipProxy.ensureAirshipReady()
            return AirshipActionRunner()
        }

        self.privacyManager = AirshipPrivacyManagerProxy {
            try AirshipProxy.ensureAirshipReady()
            return Airship.shared.privacyManager
        }
    }

    @objc(takeOffWithJSON:withError:)
    public func _takeOff(
        json: Any
    ) throws -> NSNumber {
        return try NSNumber(value: self.takeOff(json: json))
    }

    public func takeOff(
        json: Any
    ) throws -> Bool {
        let proxyConfig = try JSONDecoder().decode(
            ProxyConfig.self,
            from: try JSONUtils.data(json)
        )

        return try takeOff(config: proxyConfig)

    }

    public func takeOff(
        config: ProxyConfig
    ) throws -> Bool {
        self.proxyStore.config = config
        try? attemptTakeOff()
        return Airship.isFlying
    }


    @objc
    public func isFlying(
    ) -> Bool {
        return Airship.isFlying
    }

    private func attemptTakeOff() throws {
        guard !Airship.isFlying else {
            return;
        }

        AirshipLogger.debug("attemptTakeOff: \(String(describing: self.launchOptions))")

        var airshipConfig: Config? = nil

        if let config = self.proxyStore.config {
            airshipConfig = config.airshipConfig
            guard airshipConfig?.validate() == true else {
                throw AirshipProxyError.invalidConfig(
                    "Invalid config: \(String(describing: airshipConfig))"
                )
            }
        } else {
            airshipConfig = Config.default()
            guard airshipConfig?.validate() == true else {
                return
            }
        }

        guard let airshipConfig = airshipConfig else {
            return
        }

        AirshipLogger.debug("Taking off! \(airshipConfig)")
        Airship.takeOff(airshipConfig, launchOptions: launchOptions)
        Airship.shared.deepLinkDelegate = self.airshipDelegate
        Airship.push.registrationDelegate = self.airshipDelegate
        Airship.push.pushNotificationDelegate = self.airshipDelegate
        PreferenceCenter.shared.openDelegate = self.airshipDelegate
        MessageCenter.shared.displayDelegate = self.airshipDelegate

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.UAInboxMessageListUpdated,
            object: nil,
            queue: .main
        ) { _ in
            self.airshipDelegate.messageCenterInboxUpdated()
        }

        NotificationCenter.default.addObserver(
            forName: Channel.channelCreatedEvent,
            object: nil,
            queue: .main
        ) { _ in
            self.airshipDelegate.channelCreated()
        }

        self.onAirshipReady?()

        Airship.push.defaultPresentationOptions = self.proxyStore.foregroundPresentationOptions

        if let categories = PushUtils.loadCategories() {
            Airship.push.customCategories = categories
        }
    }

    private static func ensureAirshipReady() throws {
        guard Airship.isFlying else {
            throw AirshipProxyError.takeOffNotCalled
        }
    }
}

