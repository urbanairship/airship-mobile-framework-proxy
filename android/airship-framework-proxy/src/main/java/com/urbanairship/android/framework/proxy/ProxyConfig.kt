package com.urbanairship.android.framework.proxy

import com.urbanairship.AirshipConfigOptions.Site
import com.urbanairship.PrivacyManager.Feature
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue

public data class ProxyConfig(
    val defaultEnvironment: Environment?,
    val productionEnvironment: Environment?,
    val developmentEnvironment: Environment?,
    @Site val site: String?,
    val inProduction: Boolean?,
    val initialConfigUrl: String?,
    val urlAllowList: List<String>?,
    val urlAllowListScopeJavaScriptInterface: List<String>?,
    val urlAllowListScopeOpenUrl: List<String>?,
    val isChannelCaptureEnabled: Boolean?,
    val isChannelCreationDelayEnabled: Boolean?,
    @Feature val enabledFeatures: Int?,
    val autoPauseInAppAutomationOnLaunch: Boolean?,
    val androidConfig: Android?
) : JsonSerializable {

    public constructor(config: JsonMap) : this(defaultEnvironment = config.get("default")?.map?.let { Environment(it) },
        productionEnvironment = config.get("production")?.map?.let { Environment(it) },
        developmentEnvironment = config.get("development")?.map?.let { Environment(it) },
        site = config.get("site")?.string?.let { Utils.parseSite(it) },
        inProduction = config.get("inProduction")?.boolean,
        initialConfigUrl = config.get("initialConfigUrl")?.string,
        urlAllowList = config.get("urlAllowList")?.list?.mapNotNull { it.string },
        urlAllowListScopeJavaScriptInterface = config.get("urlAllowListScopeJavaScriptInterface")?.list?.mapNotNull { it.string },
        urlAllowListScopeOpenUrl = config.get("urlAllowListScopeOpenUrl")?.list?.mapNotNull { it.string },
        isChannelCaptureEnabled = config.get("isChannelCaptureEnabled")?.boolean,
        isChannelCreationDelayEnabled = config.get("isChannelCreationDelayEnabled")?.boolean,
        enabledFeatures = config.get("enabledFeatures")?.let { Utils.parseFeatures(it) },
        autoPauseInAppAutomationOnLaunch = config.get("autoPauseInAppAutomationOnLaunch")?.boolean,
        androidConfig = config.get("android")?.map?.let { Android(it) })

    override fun toJsonValue(): JsonValue {
        return JsonMap.newBuilder()
            .put("default", defaultEnvironment)
            .put("production", productionEnvironment)
            .put("development", developmentEnvironment)
            .put("site", site?.let { Utils.siteString(site) })
            .putOpt("initialConfigUrl", initialConfigUrl)
            .putOpt("urlAllowList", urlAllowList)
            .putOpt("urlAllowListScopeJavaScriptInterface", urlAllowListScopeJavaScriptInterface)
            .putOpt("urlAllowListScopeOpenUrl", urlAllowListScopeOpenUrl)
            .putOpt("isChannelCaptureEnabled", isChannelCaptureEnabled)
            .putOpt("isChannelCreationDelayEnabled", isChannelCreationDelayEnabled)
            .putOpt("enabledFeatures", enabledFeatures?.let { Utils.featureNames(it) })
            .putOpt("autoPauseInAppAutomationOnLaunch", autoPauseInAppAutomationOnLaunch)
            .putOpt("android", androidConfig)
            .build()
            .toJsonValue()
    }

    public data class Environment(
        val appKey: String?, val appSecret: String?, val logLevel: Int?
    ) : JsonSerializable {

        override fun toJsonValue(): JsonValue = JsonMap.newBuilder()
            .putOpt("appKey", appKey)
            .putOpt("appSecret", appSecret)
            .putOpt("logLevel", logLevel?.let { Utils.logLevelString(it) })
            .build()
            .toJsonValue()

        public constructor(config: JsonMap) : this(appKey = config.get("appKey")?.string,
            appSecret = config.get("appSecret")?.string,
            logLevel = config.get("logLevel")?.string?.let { Utils.parseLogLevel(it) })
    }

    public data class Android(
        val appStoreUri: String?, val fcmFirebaseAppName: String?, val notificationConfig: NotificationConfig?
    ) : JsonSerializable {

        override fun toJsonValue(): JsonValue = JsonMap.newBuilder()
            .putOpt("appStoreUri", appStoreUri)
            .putOpt("fcmFirebaseAppName", fcmFirebaseAppName)
            .putOpt("notificationConfig", notificationConfig)
            .build()
            .toJsonValue()

        internal constructor(config: JsonMap) : this(appStoreUri = config.get("appStoreUri")?.string,
            fcmFirebaseAppName = config.get("fcmFirebaseAppName")?.string,
            notificationConfig = config.get("notificationConfig")?.map?.let { NotificationConfig(it) })
    }
}
