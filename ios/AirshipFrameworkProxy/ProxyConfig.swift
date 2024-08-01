/* Copyright Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
#endif


public struct ProxyConfig: Codable {
    public enum LogLevel: String, Codable {
        case verbose
        case debug
        case info
        case warning
        case error
        case none
    }

    public enum Site: String, Codable {
        case eu
        case us
    }

    public struct Environment: Codable {
        public let logLevel: LogLevel?
        public let appKey: String?
        public let appSecret: String?
        public let ios: PlatformConfig?

        public init(logLevel: LogLevel?, appKey: String?, appSecret: String?, ios: PlatformConfig?) {
            self.logLevel = logLevel
            self.appKey = appKey
            self.appSecret = appSecret
            self.ios = ios
        }

        public struct PlatformConfig: Codable {
            public let logPrivacyLevel: LogLevelPrivacy?

            public init(logPrivacyLevel: LogLevelPrivacy?) {
                self.logPrivacyLevel = logPrivacyLevel
            }
        }

        public enum LogLevelPrivacy: String, Codable {
            case `public` = "public"
            case `private` = "private"

            var airshipLevel: AirshipLogPrivacyLevel {
                switch(self) {
                case .private: .private
                case .public: .public
                }
            }
        }
    }

    public struct PlatformConfig: Codable {
        public let itunesID: String?
        public let messageCenterStyleConfig: String?
        public let useUserPreferredLocale: Bool?
        public let isWebViewInspectionEnabled: Bool?

        public init(
            itunesID: String?  = nil,
            messageCenterStyleConfig: String? = nil,
            useUserPreferredLocale: Bool? = nil,
            isWebViewInspectionEnabled: Bool? = nil
        ) {
            self.itunesID = itunesID
            self.messageCenterStyleConfig = messageCenterStyleConfig
            self.useUserPreferredLocale = useUserPreferredLocale
            self.isWebViewInspectionEnabled = isWebViewInspectionEnabled
        }

        private enum CodingKeys: String, CodingKey {
            case itunesID = "itunesId"
            case messageCenterStyleConfig
            case useUserPreferredLocale
            case isWebViewInspectionEnabled
        }
    }

    public var defaultEnvironment: Environment?
    public var productionEnvironment: Environment?
    public var developmentEnvironment: Environment?
    public var inProduction: Bool?
    public var ios: PlatformConfig?
    public var site: Site?
    public var isChannelCreationDelayEnabled: Bool?
    public var enabledFeatures: AirshipFeature?
    public var urlAllowListScopeOpenURL: [String]?
    public var urlAllowListScopeJavaScriptInterface: [String]?
    public var urlAllowList: [String]?
    public var initialConfigURL: String?
    public var isChannelCaptureEnabled: Bool?
    public var suppressAllowListError: Bool?
    public var autoPauseInAppAutomationOnLaunch: Bool?
    
    public init(
        defaultEnvironment: Environment? = nil,
        productionEnvironment: Environment? = nil,
        developmentEnvironment: Environment? = nil,
        inProduction: Bool? = nil,
        ios: PlatformConfig? = nil,
        site: Site? = nil,
        isChannelCreationDelayEnabled: Bool? = nil,
        enabledFeatures: AirshipFeature? = nil,
        urlAllowListScopeOpenURL: [String]? = nil,
        urlAllowListScopeJavaScriptInterface: [String]? = nil,
        urlAllowList: [String]? = nil,
        initialConfigURL: String? = nil,
        isChannelCaptureEnabled: Bool? = nil,
        suppressAllowListError: Bool? = nil,
        autoPauseInAppAutomationOnLaunch: Bool? = nil
    ) {
        self.defaultEnvironment = defaultEnvironment
        self.productionEnvironment = productionEnvironment
        self.developmentEnvironment = developmentEnvironment
        self.inProduction = inProduction
        self.ios = ios
        self.site = site
        self.isChannelCreationDelayEnabled = isChannelCreationDelayEnabled
        self.enabledFeatures = enabledFeatures
        self.urlAllowListScopeOpenURL = urlAllowListScopeOpenURL
        self.urlAllowListScopeJavaScriptInterface = urlAllowListScopeJavaScriptInterface
        self.urlAllowList = urlAllowList
        self.initialConfigURL = initialConfigURL
        self.isChannelCaptureEnabled = isChannelCaptureEnabled
        self.suppressAllowListError = suppressAllowListError
        self.autoPauseInAppAutomationOnLaunch = autoPauseInAppAutomationOnLaunch
    }

    private enum CodingKeys: String, CodingKey {
        case defaultEnvironment = "default"
        case productionEnvironment = "production"
        case developmentEnvironment = "development"
        case inProduction = "inProduction"
        case ios = "ios"
        case site = "site"
        case isChannelCreationDelayEnabled = "isChannelCreationDelayEnabled"
        case enabledFeatures = "enabledFeatures"
        case urlAllowListScopeOpenURL = "urlAllowListScopeOpenUrl"
        case urlAllowListScopeJavaScriptInterface = "urlAllowListScopeJavaScriptInterface"
        case urlAllowList = "urlAllowList"
        case initialConfigURL = "initialConfigUrl"
        case isChannelCaptureEnabled = "isChannelCaptureEnabled"
        case autoPauseInAppAutomationOnLaunch = "autoPauseInAppAutomationOnLaunch"
    }
}

extension ProxyConfig.LogLevel {
    var airshipLogLevel: AirshipLogLevel {
        switch(self) {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warn
        case .error: return .error
        case .none: return .none
        }
    }
}
extension ProxyConfig.Site {
    var airshipSite: CloudSite {
        switch (self) {
        case .eu: return .eu
        case .us: return .us
        }
    }
}

extension AirshipConfig {

    public func applyProxyConfig(proxyConfig: ProxyConfig) {
        // App credentials
        if let appKey = proxyConfig.defaultEnvironment?.appKey,
           let appSecret = proxyConfig.defaultEnvironment?.appSecret {
            self.defaultAppKey = appKey
            self.defaultAppSecret = appSecret
        }

        if let appKey = proxyConfig.productionEnvironment?.appKey,
           let appSecret = proxyConfig.productionEnvironment?.appSecret {
            self.productionAppKey = appKey
            self.productionAppSecret = appSecret
        }

        if let appKey = proxyConfig.developmentEnvironment?.appKey,
           let appSecret = proxyConfig.developmentEnvironment?.appSecret {
            self.developmentAppKey = appKey
            self.developmentAppSecret = appSecret
        }

        // Log level
        if let level = proxyConfig.productionEnvironment?.logLevel {
            self.productionLogLevel  = level.airshipLogLevel
        } else if let level = proxyConfig.defaultEnvironment?.logLevel {
            self.productionLogLevel = level.airshipLogLevel
        }

        if let level = proxyConfig.developmentEnvironment?.logLevel {
            self.developmentLogLevel = level.airshipLogLevel
        } else if let level = proxyConfig.defaultEnvironment?.logLevel {
            self.developmentLogLevel = level.airshipLogLevel
        }

        // Privacy Log Level
        if let level = proxyConfig.productionEnvironment?.ios?.logPrivacyLevel {
            self.productionLogPrivacyLevel  = level.airshipLevel
        } else if let level = proxyConfig.defaultEnvironment?.ios?.logPrivacyLevel {
            self.productionLogPrivacyLevel = level.airshipLevel
        }

        if let level = proxyConfig.developmentEnvironment?.ios?.logPrivacyLevel {
            self.developmentLogPrivacyLevel = level.airshipLevel
        } else if let level = proxyConfig.defaultEnvironment?.ios?.logPrivacyLevel {
            self.developmentLogPrivacyLevel = level.airshipLevel
        }

        if let inProduction = proxyConfig.inProduction {
            self.inProduction = inProduction
        }

        if let isChannelCreationDelayEnabled = proxyConfig.isChannelCreationDelayEnabled {
            self.isChannelCreationDelayEnabled = isChannelCreationDelayEnabled
        }

        if let itunesID = proxyConfig.ios?.itunesID {
            self.itunesID = itunesID
        }

        if let isWebViewInspectionEnabled = proxyConfig.ios?.isWebViewInspectionEnabled {
            self.isWebViewInspectionEnabled = isWebViewInspectionEnabled
        }

        if let messageCenterStyleConfig = proxyConfig.ios?.messageCenterStyleConfig {
            self.messageCenterStyleConfig = messageCenterStyleConfig
        }

        if let useUserPreferredLocale = proxyConfig.ios?.useUserPreferredLocale {
            self.useUserPreferredLocale = useUserPreferredLocale
        }

        if let site = proxyConfig.site {
            self.site = site.airshipSite
        }

        if let initialConfigURL = proxyConfig.initialConfigURL {
            self.initialConfigURL = initialConfigURL
        }

        if let isChannelCaptureEnabled = proxyConfig.isChannelCaptureEnabled {
            self.isChannelCaptureEnabled = isChannelCaptureEnabled
        }

        if let enabledFeatures = proxyConfig.enabledFeatures {
            self.enabledFeatures = enabledFeatures
        }

        if let allowList = proxyConfig.urlAllowList {
            self.urlAllowList = allowList
        }

        if let allowList = proxyConfig.urlAllowListScopeOpenURL {
            self.urlAllowListScopeOpenURL = allowList
        }

        if let allowList = proxyConfig.urlAllowListScopeJavaScriptInterface {
            self.urlAllowListScopeJavaScriptInterface = allowList
        }
        
        if let autoPauseInAppAutomation = proxyConfig.autoPauseInAppAutomationOnLaunch {
            self.autoPauseInAppAutomationOnLaunch = autoPauseInAppAutomation
        }
    }
}
