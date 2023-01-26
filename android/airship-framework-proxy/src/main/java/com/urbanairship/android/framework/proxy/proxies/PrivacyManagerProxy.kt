package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.PrivacyManager
import com.urbanairship.android.framework.proxy.Utils
import com.urbanairship.json.JsonValue

public class PrivacyManagerProxy internal constructor(
    private val privacyManagerProvider: () -> PrivacyManager
) {

    public fun setEnabledFeatures(featureNames: List<String>) {
        setEnabledFeatures(
            JsonValue.wrapOpt(featureNames)
        )
    }

    public fun setEnabledFeatures(featureNames: JsonValue) {
        setEnabledFeatures(
            Utils.parseFeatures(featureNames)
        )
    }

    public fun setEnabledFeatures(features: Int) {
        privacyManagerProvider().setEnabledFeatures(features)
    }

    public fun getFeatureNames(): List<String> {
        return Utils.featureNames(privacyManagerProvider().enabledFeatures)
    }

    public fun enableFeatures(featureNames: List<String>) {
        enableFeatures(
            JsonValue.wrapOpt(featureNames)
        )
    }

    public fun enableFeatures(featureNames: JsonValue) {
        enableFeatures(
            Utils.parseFeatures(featureNames)
        )
    }

    public fun enableFeatures(features: Int) {
        privacyManagerProvider().enable(features)
    }

    public fun disableFeatures(featureNames: List<String>) {
        disableFeatures(
            JsonValue.wrapOpt(featureNames)
        )
    }

    public fun disableFeatures(featureNames: JsonValue) {
        disableFeatures(
            Utils.parseFeatures(featureNames)
        )
    }

    public fun disableFeatures(features: Int) {
        privacyManagerProvider().disable(features)
    }

    public fun isFeatureEnabled(featureNames: List<String>): Boolean {
        return isFeatureEnabled(
            JsonValue.wrapOpt(featureNames)
        )
    }

    public fun isFeatureEnabled(featureNames: JsonValue): Boolean {
        return isFeatureEnabled(
            Utils.parseFeatures(featureNames)
        )
    }

    public fun isFeatureEnabled(features: Int): Boolean {
        return privacyManagerProvider().isEnabled(features)
    }
}