/* Copyright Airship and Contributors */

import Foundation
import Combine
import UserNotifications
import UIKit

#if canImport(AirshipKit)
public import AirshipKit
#elseif canImport(AirshipCore)
public import AirshipCore
import AirshipAutomation
import AirshipMessageCenter
import AirshipFeatureFlags
import AirshipPreferenceCenter
#endif

public enum AirshipProxyError: Error {
    case takeOffNotCalled
    case invalidConfig(String)
}

public protocol AirshipProxyDelegate {
    @MainActor
    func migrateData(store: ProxyStore)
    @MainActor
    func loadDefaultConfig() -> AirshipConfig
    @MainActor
    func onAirshipReady()
}

public final class AirshipProxy: Sendable {

    private static let extender: (any AirshipPluginExtenderProtocol.Type)? = {
        NSClassFromString("AirshipPluginExtender") as? any AirshipPluginExtenderProtocol.Type
    }()

    @MainActor
    public var delegate: (any AirshipProxyDelegate)?
    @MainActor
    private var migrateCalled: Bool = false
    @MainActor
    private var subscriptions: Set<AnyCancellable> = Set()

    private let proxyStore: ProxyStore

    @MainActor
    private var airshipDelegate: AirshipDelegate?

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
    public let featureFlagManager: AirshipFeatureFlagManagerProxy

    public static let shared: AirshipProxy = AirshipProxy()

    init(
        proxyStore: ProxyStore = ProxyStore.shared
    ) {
        self.proxyStore = proxyStore
        self.locale = AirshipLocaleProxy {
            try AirshipProxy.ensureAirshipReady()
            return Airship.localeManager
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
            return Airship.messageCenter
        }

        self.preferenceCenter = AirshipPreferenceCenterProxy(
            proxyStore: proxyStore
        ) {
            try AirshipProxy.ensureAirshipReady()
            return Airship.preferenceCenter
        }
        self.inApp = AirshipInAppProxy {
            try AirshipProxy.ensureAirshipReady()
            return Airship.inAppAutomation
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
            return Airship.privacyManager
        }

        self.featureFlagManager = AirshipFeatureFlagManagerProxy {
            try AirshipProxy.ensureAirshipReady()
            return Airship.featureFlagManager
        }

    }


    @MainActor
    public func takeOff(
        json: Any,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) throws -> Bool {
        let proxyConfig = try JSONDecoder().decode(
            ProxyConfig.self,
            from: try AirshipJSONUtils.data(json)
        )

        return try takeOff(config: proxyConfig, launchOptions: launchOptions)

    }

    @MainActor
    public func takeOff(
        config: ProxyConfig,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) throws -> Bool {
        self.proxyStore.config = config
        try? attemptTakeOff(launchOptions: launchOptions)
        return Airship.isFlying
    }

    @objc
    public func isFlying(
    ) -> Bool {
        return Airship.isFlying
    }

    private static func ensureAirshipReady() throws {
        guard Airship.isFlying else {
            throw AirshipProxyError.takeOffNotCalled
        }
    }

    @MainActor
    public func attemptTakeOff(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) throws {
        guard !Airship.isFlying else {
            return;
        }

        if (!migrateCalled) {
            self.delegate?.migrateData(store: self.proxyStore)
            migrateCalled = true
        }

        AirshipLogger.debug("attemptTakeOff: \(String(describing: launchOptions))")

        let airshipConfig = makeConfig()

        self.airshipDelegate = AirshipDelegate(proxyStore: proxyStore)

        AirshipLogger.debug("Taking off! \(airshipConfig)")
        try Airship.takeOff(airshipConfig, launchOptions: launchOptions)
        Airship.deepLinkDelegate = self.airshipDelegate
        Airship.push.registrationDelegate = self.airshipDelegate
        Airship.push.pushNotificationDelegate = self.airshipDelegate
        Airship.preferenceCenter.openDelegate = self.airshipDelegate
        Airship.messageCenter.displayDelegate = self.airshipDelegate

        Task {
            let updates = await Airship.push.notificationStatusUpdates.map {
                NotificationStatus(airshipStatus: $0)
            }

            for await update in updates {
                AirshipProxyEventEmitter.shared.addEvent(
                    NotificationStatusChangedEvent(status: update),
                    replacePending: true
                )
            }
        }

        Task {
            await EmbeddedEventEmitter.shared.start()
        }

        let delegate = self.airshipDelegate
        NotificationCenter.default.addObserver(
            forName: AirshipNotifications.MessageCenterListUpdated.name,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                delegate?.messageCenterInboxUpdated()
            }
        }

        NotificationCenter.default.addObserver(
            forName: AirshipNotifications.ChannelCreated.name,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                delegate?.channelCreated()
            }
        }

        Airship.push.defaultPresentationOptions = self.proxyStore.foregroundPresentationOptions

        if let categories = self.loadCategories() {
            Airship.push.customCategories = categories
        }

        self.delegate?.onAirshipReady()
        AirshipProxy.extender?.onAirshipReady()
    }

    private func loadCategories() -> Set<UNNotificationCategory>? {
        let categoriesPath = Bundle.main.path(
            forResource: "UACustomNotificationCategories",
            ofType: "plist"
        )

        guard let categoriesPath = categoriesPath else {
            return nil
        }

        return NotificationCategories.createCategories(
            fromFile: categoriesPath
        )
    }

    @MainActor
    private func makeConfig() -> AirshipConfig {
        var airshipConfig: AirshipConfig = delegate?.loadDefaultConfig() ?? (try? AirshipConfig.default()) ?? AirshipConfig()
        airshipConfig.requireInitialRemoteConfigEnabled = true

        if let config = self.proxyStore.config {
            airshipConfig.applyProxyConfig(proxyConfig: config)
        }

        AirshipProxy.extender?.extendConfig(config: airshipConfig)

        return airshipConfig
    }
}

