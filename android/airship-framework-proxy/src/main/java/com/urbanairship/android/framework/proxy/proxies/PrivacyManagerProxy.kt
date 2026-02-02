package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.PrivacyManager
import com.urbanairship.UALog
import com.urbanairship.android.framework.proxy.Utils
import com.urbanairship.json.JsonValue

public class PrivacyManagerProxy internal constructor(
    private val privacyManagerProvider: () -> PrivacyManager
) {
    public fun setEnabledFeatures(featureNames: List<String>) {
        UALog.v { "setEnabledFeatures called, featureNames=$featureNames" }
        setEnabledFeatures(
            JsonValue.wrapOpt(featureNames)
        )
    }

    public fun setEnabledFeatures(featureNames: JsonValue) {
        setEnabledFeatures(
            Utils.parseFeatures(featureNames)
        )
    }

    public fun setEnabledFeatures(features: PrivacyManager.Feature) {
        privacyManagerProvider().setEnabledFeatures(features)
    }

    public fun getFeatureNames(): List<String> {
        UALog.v { "getFeatureNames called" }
        return Utils.featureNames(privacyManagerProvider().enabledFeatures)
    }

    public fun enableFeatures(featureNames: List<String>) {
        UALog.v { "enableFeatures called, featureNames=$featureNames" }
        enableFeatures(
            JsonValue.wrapOpt(featureNames)
        )
    }

    public fun enableFeatures(featureNames: JsonValue) {
        enableFeatures(
            Utils.parseFeatures(featureNames)
        )
    }

    public fun enableFeatures(features: PrivacyManager.Feature) {
        privacyManagerProvider().enable(features)
    }

    public fun disableFeatures(featureNames: List<String>) {
        UALog.v { "disableFeatures called, featureNames=$featureNames" }
        disableFeatures(
            JsonValue.wrapOpt(featureNames)
        )
    }

    public fun disableFeatures(featureNames: JsonValue) {
        disableFeatures(
            Utils.parseFeatures(featureNames)
        )
    }

    public fun disableFeatures(features: PrivacyManager.Feature) {
        privacyManagerProvider().disable(features)
    }

    public fun isFeatureEnabled(featureNames: List<String>): Boolean {
        UALog.v { "isFeatureEnabled called, featureNames=$featureNames" }
        return isFeatureEnabled(
            JsonValue.wrapOpt(featureNames)
        )
    }

    public fun isFeatureEnabled(featureNames: JsonValue): Boolean {
        return isFeatureEnabled(
            Utils.parseFeatures(featureNames)
        )
    }

    public fun isFeatureEnabled(features: PrivacyManager.Feature): Boolean {
        return privacyManagerProvider().isEnabled(features)
    }
}
