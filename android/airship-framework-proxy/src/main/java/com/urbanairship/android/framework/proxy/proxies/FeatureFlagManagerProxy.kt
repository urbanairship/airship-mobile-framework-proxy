package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.featureflag.FeatureFlag
import com.urbanairship.featureflag.FeatureFlagManager
import com.urbanairship.featureflag.FeatureFlagResultCache
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf
import com.urbanairship.json.requireField
import kotlin.time.Duration

public class FeatureFlagManagerProxy internal constructor(
    private val featureFlagManagerProvider: () -> FeatureFlagManager
) {

    public val resultCache: ResultCacheProxy = ResultCacheProxy { featureFlagManagerProvider().resultCache }

    public class ResultCacheProxy  internal constructor(private val cacheProvider: () -> FeatureFlagResultCache) {

        public suspend fun cache(flag: FeatureFlagProxy, ttl: Duration) {
            cacheProvider().cache(flag.original, ttl)
        }

        public suspend fun flag(name: String): FeatureFlagProxy? {
            return cacheProvider().flag(name)?.let { FeatureFlagProxy(it) }
        }

        public suspend fun removeCachedFlag(name: String) {
            return cacheProvider().removeCachedFlag(name)
        }
    }

    public suspend fun flag(name: String, useResultCache: Boolean = true): FeatureFlagProxy {
        val flag = featureFlagManagerProvider().flag(name, useResultCache).getOrThrow()
        return FeatureFlagProxy(flag)
    }

    public fun trackInteraction(flag: FeatureFlagProxy) {
        featureFlagManagerProvider().trackInteraction(flag.original)
    }
}

public data class FeatureFlagProxy(
    internal val original: FeatureFlag,
) : JsonSerializable {

    public constructor(jsonValue: JsonValue): this(
        FeatureFlag.fromJson(jsonValue.requireMap().requireField("_internal"))
    )

    override fun toJsonValue(): JsonValue = jsonMapOf(
        "isEligible" to original.isEligible,
        "exists" to original.exists,
        "variables" to original.variables,
        "_internal" to original
    ).toJsonValue()
}
