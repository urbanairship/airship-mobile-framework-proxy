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
    public let channelCaptureEnabled: Bool?

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
        case channelCaptureEnabled = "channelCaptureEnabled"

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

extension ProxyConfig {
    var airshipConfig: Config {
        let config = Config.default()
        config.requireInitialRemoteConfigEnabled = true

        if let appKey = defaultEnvironment?.appKey,
           let appSecret = defaultEnvironment?.appSecret {
            config.defaultAppKey = appKey
            config.defaultAppSecret = appSecret
        }

        if let appKey = productionEnvironment?.appKey,
           let appSecret = productionEnvironment?.appSecret {
            config.productionAppKey = appKey
            config.productionAppSecret = appSecret
        }

        if let appKey = developmentEnvironment?.appKey,
           let appSecret = developmentEnvironment?.appSecret {
            config.developmentAppKey = appKey
            config.developmentAppSecret = appSecret
        }

        if let level = productionEnvironment?.logLevel {
            config.productionLogLevel  = level.airshipLogLevel
        } else if let level = defaultEnvironment?.logLevel {
            config.productionLogLevel  = level.airshipLogLevel
        }

        if let level = developmentEnvironment?.logLevel {
            config.developmentLogLevel  = level.airshipLogLevel
        } else if let level = defaultEnvironment?.logLevel {
            config.developmentLogLevel  = level.airshipLogLevel
        }

        if let inProduction = inProduction {
            config.inProduction = inProduction
        }

        if let isChannelCreationDelayEnabled = isChannelCreationDelayEnabled {
            config.isChannelCreationDelayEnabled = isChannelCreationDelayEnabled
        }

        if let itunesID = ios?.itunesID {
            config.itunesID = itunesID
        }

        if let site = site {
            config.site = site.airshipSite
        }

        if let initialConfigURL = initialConfigURL {
            config.initialConfigURL = initialConfigURL
        }

        if let channelCaptureEnabled = channelCaptureEnabled {
            config.isChannelCaptureEnabled = channelCaptureEnabled
        }

        if let enabledFeatures = enabledFeatures {
            config.enabledFeatures = enabledFeatures
        }

        if let allowList = urlAllowList {
            config.urlAllowList = allowList
        }

        if let allowList = urlAllowListScopeOpenURL {
            config.urlAllowListScopeOpenURL = allowList
        }

        if let allowList = urlAllowListScopeJavaScriptInterface {
            config.urlAllowListScopeJavaScriptInterface = allowList
        }

        return config
    }
}

