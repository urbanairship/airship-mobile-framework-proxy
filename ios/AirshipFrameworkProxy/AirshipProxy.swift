import Foundation
import UIKit
import AirshipKit

public enum AirshipProxyError: Error {
    case takeOffNotCalled
    case invalidConfig(String)
}

public class AirshipProxy {
    private let proxyStore: ProxyStore
    private let launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    private let onAirshipReady: (() -> Void)?
    private let airshipDelegate: AirshipDelegate

    public let locale: AirshipLocaleProxy
    public let push: AirshipPushProxy
    public let channel: AirshipChannelProxy
    public let messageCenter: AirshipMessageCenterProxy
    public let preferenceCenter: AirshipPreferenceCenterProxy
    public let inApp: AirshipInAppProxy
    public let contact: AirshipContactProxy
    public let analytics: AirshipAnalyticsProxy
    public let action: AirshipActionProxy
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

    public func takeOff(
        _ config: [String : Any]
    ) throws -> Bool {
        let proxyConfig = try JSONDecoder().decode(
            ProxyConfig.self,
            from: try JSONUtils.data(config)
        )
        self.proxyStore.config = proxyConfig
        try attemptTakeOff()
        return Airship.isFlying
    }

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

