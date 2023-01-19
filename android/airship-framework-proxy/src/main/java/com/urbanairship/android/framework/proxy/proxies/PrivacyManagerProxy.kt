package com.urbanairship.android.framework.proxy.proxies

public class PrivacyManagerProxy {

//
//    /**
//     * Sets the current enabled features.
//     *
//     * @param features The features to set as enabled.
//     * @param promise  The promise.
//     */
//    fun setEnabledFeatures(features: ReadableArray, promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        try {
//            UAirship.shared().privacyManager.setEnabledFeatures(parseFeatures(features))
//        } catch (e: Exception) {
//            promise.reject(INVALID_FEATURE_ERROR_CODE, INVALID_FEATURE_ERROR_MESSAGE, e)
//        }
//    }
//
//    /**
//     * Gets the current enabled features.
//     *
//     * @param promise The promise.
//     * @return The enabled features.
//     */
//    fun getEnabledFeatures(promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        val enabledFeatures =
//            Utils.convertFeatures(UAirship.shared().privacyManager.enabledFeatures)
//        promise.resolve(toWritableArray(enabledFeatures))
//    }
//
//    /**
//     * Enables features.
//     *
//     * @param features The features to enable.
//     * @param promise  The promise.
//     */
//    fun enableFeature(features: ReadableArray, promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        try {
//            UAirship.shared().privacyManager.enable(parseFeatures(features))
//        } catch (e: Exception) {
//            promise.reject(INVALID_FEATURE_ERROR_CODE, INVALID_FEATURE_ERROR_MESSAGE, e)
//        }
//    }
//
//    /**
//     * Disables features.
//     *
//     * @param features The features to disable.
//     * @param promise  The promise.
//     */
//    fun disableFeature(features: ReadableArray, promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        try {
//            UAirship.shared().privacyManager.disable(parseFeatures(features))
//        } catch (e: Exception) {
//            promise.reject(INVALID_FEATURE_ERROR_CODE, INVALID_FEATURE_ERROR_MESSAGE, e)
//        }
//    }
//
//    /**
//     * Checks if a given feature is enabled.
//     *
//     * @param features The features to check.
//     * @param promise  The promise.
//     * @return `true` if the provided features are enabled, otherwise `false`.
//     */
//    fun isFeatureEnabled(features: ReadableArray, promise: Promise) {
//        if (!Utils.ensureAirshipReady(promise)) {
//            return
//        }
//        try {
//            val enabled = UAirship.shared().privacyManager.isEnabled(parseFeatures(features))
//            promise.resolve(enabled)
//        } catch (e: Exception) {
//            promise.reject(INVALID_FEATURE_ERROR_CODE, INVALID_FEATURE_ERROR_MESSAGE, e)
//        }
//    }
}