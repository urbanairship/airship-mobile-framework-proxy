package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.featureflag.FeatureFlag
import com.urbanairship.featureflag.FeatureFlagManager
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf

public class FeatureFlagManagerProxy internal constructor(private val featureFlagManagerProvider: () -> FeatureFlagManager) {
    public suspend fun flag(name: String): FeatureFlagProxy {
        val flag = featureFlagManagerProvider().flag(name).getOrThrow()
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
        FeatureFlag.fromJson(jsonValue)
    )
    override fun toJsonValue(): JsonValue = jsonMapOf(
        "isEligible" to original.isEligible,
        "exists" to original.exists,
        "variables" to original.variables,
        "_internal" to original
    ).toJsonValue()
}
