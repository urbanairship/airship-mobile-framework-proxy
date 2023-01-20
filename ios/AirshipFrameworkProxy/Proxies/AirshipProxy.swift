import Foundation
import AirshipKit

public enum AirshipProxyError: Error {
    case takeOffNotCalled
    case invalidConfig(String)
}

public protocol AirshipProxyDelegate {
    func migrateData(store: ProxyStore)
    func loadDefaultConfig() -> Config
    func onAirshipReady()
}

@objc
public class AirshipProxy: NSObject {

    public var delegate: AirshipProxyDelegate?
    private var migrateCalled: Bool = false

    private let proxyStore: ProxyStore
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

    @objc
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

        self.airshipDelegate = AirshipDelegate(proxyStore: proxyStore)
        super.init()
    }

    @objc(takeOffWithJSON:launchOptions:withError:)
    public func _takeOff(
        json: Any,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) throws -> NSNumber {
        return try NSNumber(
            value: self.takeOff(
                json: json,
                launchOptions: launchOptions
            )
        )
    }

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

    @objc
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

        let airshipConfig: Config = delegate?.loadDefaultConfig() ?? Config.default()
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

        self.delegate?.onAirshipReady()

        Airship.push.defaultPresentationOptions = self.proxyStore.foregroundPresentationOptions

        if let categories = PushUtils.loadCategories() {
            Airship.push.customCategories = categories
        }
    }
}

