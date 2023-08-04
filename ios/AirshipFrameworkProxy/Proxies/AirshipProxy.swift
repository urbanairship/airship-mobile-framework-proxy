import Foundation
import Combine
import AirshipKit

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
            from: try JSONUtils.data(json)
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

        let airshipConfig: AirshipConfig = delegate?.loadDefaultConfig() ?? AirshipConfig.default()
        airshipConfig.requireInitialRemoteConfigEnabled = true

        if let config = self.proxyStore.config {
            airshipConfig.applyProxyConfig(proxyConfig: config)
            guard airshipConfig.validate() == true else {
                throw AirshipProxyError.invalidConfig(
                    "Invalid config: \(String(describing: airshipConfig))"
                )
            }
        } else {
            guard airshipConfig.validate() == true else {
                return
            }
        }

        AirshipLogger.debug("Taking off! \(airshipConfig)")
        Airship.takeOff(airshipConfig, launchOptions: launchOptions)
        Airship.shared.deepLinkDelegate = self.airshipDelegate
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
                        NotificationStatusChangedEvent(status: status)
                    )
                }
            }
            .store(in: &self.subscriptions)

        NotificationCenter.default.addObserver(
            forName: MessageCenterInbox.messageListUpdatedEvent,
            object: nil,
            queue: .main
        ) { _ in
            self.airshipDelegate.messageCenterInboxUpdated()
        }

        NotificationCenter.default.addObserver(
            forName: AirshipChannel.channelCreatedEvent,
            object: nil,
            queue: .main
        ) { _ in
            self.airshipDelegate.channelCreated()
        }

        self.delegate?.onAirshipReady()

        Airship.push.defaultPresentationOptions = self.proxyStore.foregroundPresentationOptions

        if let categories = self.loadCategories() {
            Airship.push.customCategories = categories
        }
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
}

