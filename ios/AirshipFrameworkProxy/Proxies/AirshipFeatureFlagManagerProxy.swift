/* Copyright Urban Airship and Contributors */

import Foundation

#if canImport(AirshipKit)
import AirshipKit
#elseif canImport(AirshipCore)
import AirshipCore
import AirshipFeatureFlags
#endif

public final class AirshipFeatureFlagManagerProxy: Sendable {
    public final class ResultCacheProxy: Sendable {
        private let cacheProvider: @Sendable () throws -> any FeatureFlagResultCache

        init(cacheProvider: @Sendable @escaping () throws -> any FeatureFlagResultCache) {
            self.cacheProvider = cacheProvider
        }

        private var cache: any FeatureFlagResultCache {
            get throws { try cacheProvider() }
        }

        public func cache(flag: FeatureFlagProxy, ttl: TimeInterval) async throws {
            try await self.cache.cache(flag: flag.original, ttl: ttl)
        }

        public func flag(name: String) async throws -> FeatureFlagProxy? {
            guard let flag = try await self.cache.flag(name: name) else {
                return nil
            }
            return FeatureFlagProxy(flag: flag)
        }

        public func removeCachedFlag(name: String) async throws {
            try await self.cache.removeCachedFlag(name: name)
        }
    }

    private let featureFlagManagerProvider: @Sendable () throws -> any FeatureFlagManager

    private var featureFlagManager: any FeatureFlagManager {
        get throws { try featureFlagManagerProvider() }
    }

    init(featureFlagManagerProvider: @Sendable @escaping () throws -> any FeatureFlagManager) {
        self.featureFlagManagerProvider = featureFlagManagerProvider
        self.resultCache = ResultCacheProxy {
            return try featureFlagManagerProvider().resultCache
        }
    }

    public let resultCache: ResultCacheProxy

    public func flag(name: String, useResultCache: Bool = true) async throws -> FeatureFlagProxy {
        let flag = try await self.featureFlagManager.flag(name: name, useResultCache: useResultCache)
        return FeatureFlagProxy(flag: flag)
    }

    public func trackInteraction(flag: FeatureFlagProxy) throws {
        try self.featureFlagManager.trackInteraction(flag: flag.original)
    }
}

// We encode `isEligible` as snake case breaking the APIs for react. This
// wraps it so we can return camelCase like all other APIs.
public struct FeatureFlagProxy: Codable, Sendable {
    let isEligible: Bool
    let exists: Bool
    let variables: AirshipJSON?
    let original: FeatureFlag

    init(flag: FeatureFlag) {
        self.isEligible = flag.isEligible
        self.exists = flag.exists
        self.variables = flag.variables
        self.original = flag
    }

    enum CodingKeys: String, CodingKey {
        case isEligible
        case exists
        case variables
        case original = "_internal"
    }
}


