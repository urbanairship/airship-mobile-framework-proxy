/* Copyright Airship and Contributors */

import Foundation
import Combine

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
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
    func migrateData(store: ProxyStore)
    func loadDefaultConfig() -> AirshipConfig
    func onAirshipReady()
}

public class AirshipProxy {

    private static let extender: AirshipPluginExtenderProtocol.Type? = {
        NSClassFromString("AirshipPluginExtender") as? AirshipPluginExtenderProtocol.Type
    }()

    public var delegate: AirshipProxyDelegate?
    private var migrateCalled: Bool = false
    private var subscriptions: Set<AnyCancellable> = Set()

    private let proxyStore: ProxyStore
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
            return Airship.privacyManager
        }

        self.featureFlagManager = AirshipFeatureFlagManagerProxy {
            try AirshipProxy.ensureAirshipReady()
            return FeatureFlagManager.shared
        }

        self.airshipDelegate = AirshipDelegate(proxyStore: proxyStore)
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

        let airshipConfig = try makeConfig()

        AirshipLogger.debug("Taking off! \(airshipConfig)")
        Airship.takeOff(airshipConfig, launchOptions: launchOptions)
        Airship.deepLinkDelegate = self.airshipDelegate
        Airship.push.registrationDelegate = self.airshipDelegate
        Airship.push.pushNotificationDelegate = self.airshipDelegate
        PreferenceCenter.shared.openDelegate = self.airshipDelegate
        MessageCenter.shared.displayDelegate = self.airshipDelegate

        Airship.push.notificationStatusPublisher
            .map { status in
                NotificationStatus(airshipStatus: status)
            }
            .filter { [proxyStore] status in
                status != proxyStore.lastNotificationStatus
            }
            .sink { status in
                Task {
                    await AirshipProxyEventEmitter.shared.addEvent(
                        NotificationStatusChangedEvent(status: status),
                        replacePending: true
                    )
                }
            }
            .store(in: &self.subscriptions)


        Task {
            await EmbeddedEventEmitter.shared.start()
        }

        NotificationCenter.default.addObserver(
            forName: AirshipNotifications.MessageCenterListUpdated.name,
            object: nil,
            queue: .main
        ) { _ in
            self.airshipDelegate.messageCenterInboxUpdated()
        }

        NotificationCenter.default.addObserver(
            forName: AirshipNotifications.ChannelCreated.name,
            object: nil,
            queue: .main
        ) { _ in
            self.airshipDelegate.channelCreated()
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
    private func makeConfig() throws -> AirshipConfig {
        let airshipConfig: AirshipConfig = delegate?.loadDefaultConfig() ?? AirshipConfig.default()
        airshipConfig.requireInitialRemoteConfigEnabled = true

        if let config = self.proxyStore.config {
            airshipConfig.applyProxyConfig(proxyConfig: config)
        }

        AirshipProxy.extender?.extendConfig(config: airshipConfig)

        guard airshipConfig.validate() else {
            throw AirshipProxyError.invalidConfig(
                "Invalid config: \(String(describing: airshipConfig))"
            )
        }

        return airshipConfig
    }
}

