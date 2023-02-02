/* Copyright Airship and Contributors */

import Foundation
import AirshipKit


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
    }

    public struct PlatformConfig: Codable {
        public let itunesID: String?

        private enum CodingKeys: String, CodingKey {
            case itunesID = "itunesId"
        }
    }

    public let defaultEnvironment: Environment?
    public let productionEnvironment: Environment?
    public let developmentEnvironment: Environment?
    public let inProduction: Bool?
    public let ios: PlatformConfig?
    public let site: Site?
    public let isChannelCreationDelayEnabled: Bool?
    public let enabledFeatures: Features?
    public let urlAllowListScopeOpenURL: [String]?
    public let urlAllowListScopeJavaScriptInterface: [String]?
    public let urlAllowList: [String]?
    public let initialConfigURL: String?
    public let isChannelCaptureEnabled: Bool?
    public let suppressAllowListError: Bool?

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
        case suppressAllowListError = "suppressAllowListError"
    }
}

extension ProxyConfig.LogLevel {
    var airshipLogLevel: LogLevel {
        switch(self) {
        case .verbose: return .trace
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

extension Config {

    func applyProxyConfig(proxyConfig: ProxyConfig) {
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

        if let level = proxyConfig.productionEnvironment?.logLevel {
            self.productionLogLevel  = level.airshipLogLevel
        } else if let level = proxyConfig.defaultEnvironment?.logLevel {
            self.productionLogLevel  = level.airshipLogLevel
        }

        if let level = proxyConfig.developmentEnvironment?.logLevel {
            self.developmentLogLevel  = level.airshipLogLevel
        } else if let level = proxyConfig.defaultEnvironment?.logLevel {
            self.developmentLogLevel  = level.airshipLogLevel
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

        if let site = proxyConfig.site {
            self.site = site.airshipSite
        }

        if let initialConfigURL = proxyConfig.initialConfigURL {
            self.initialConfigURL = initialConfigURL
        }

        if let channelCaptureEnabled = proxyConfig.isChannelCaptureEnabled {
            self.isChannelCaptureEnabled = channelCaptureEnabled
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

        if let suppressError = proxyConfig.suppressAllowListError {
            self.suppressAllowListError = suppressError
        }
    }
}

