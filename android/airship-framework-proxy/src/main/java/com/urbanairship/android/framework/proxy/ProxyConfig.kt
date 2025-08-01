package com.urbanairship.android.framework.proxy

import com.urbanairship.AirshipConfigOptions
import com.urbanairship.AirshipConfigOptions.Site
import com.urbanairship.PrivacyManager.Feature
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue

public data class ProxyConfig(
    val defaultEnvironment: Environment? = null,
    val productionEnvironment: Environment? = null,
    val developmentEnvironment: Environment? = null,
    @Site val site: String? = null,
    val inProduction: Boolean? = null,
    val initialConfigUrl: String? = null,
    val urlAllowList: List<String>? = null,
    val urlAllowListScopeJavaScriptInterface: List<String>? = null,
    val urlAllowListScopeOpenUrl: List<String>? = null,
    val isChannelCaptureEnabled: Boolean? = null,
    val isChannelCreationDelayEnabled: Boolean? = null,
    val enabledFeatures: Feature? = null,
    val autoPauseInAppAutomationOnLaunch: Boolean? = null,
    val androidConfig: Android? = null
) : JsonSerializable {

    public constructor(config: JsonMap) : this(
        defaultEnvironment = config.get("default")?.map?.let { Environment(it) },
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
        androidConfig = config.get("android")?.map?.let { Android(it) }
    )

    override fun toJsonValue(): JsonValue {
        return JsonMap.newBuilder()
            .put("default", defaultEnvironment)
            .put("production", productionEnvironment)
            .put("development", developmentEnvironment)
            .put("site", site?.let { Utils.siteString(site) })
            .putOpt("inProduction", inProduction)
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
        val appStoreUri: String?,
        val fcmFirebaseAppName: String?,
        val notificationConfig: NotificationConfig?,
        val logPrivacyLevel: AirshipConfigOptions.PrivacyLevel?
    ) : JsonSerializable {

        override fun toJsonValue(): JsonValue = JsonMap.newBuilder()
            .putOpt("appStoreUri", appStoreUri)
            .putOpt("fcmFirebaseAppName", fcmFirebaseAppName)
            .putOpt("notificationConfig", notificationConfig)
            .putOpt("logPrivacyLevel", logPrivacyLevel?.let { Utils.logPrivacyLevelString(it) })
            .build()
            .toJsonValue()

        internal constructor(config: JsonMap) : this(
            appStoreUri = config.get("appStoreUri")?.string,
            fcmFirebaseAppName = config.get("fcmFirebaseAppName")?.string,
            notificationConfig = config.get("notificationConfig")?.map?.let { NotificationConfig(it) },
            logPrivacyLevel = config.get("logPrivacyLevel")?.string?.let { Utils.parseLogPrivacyLevel(it) }
        )
    }
}
