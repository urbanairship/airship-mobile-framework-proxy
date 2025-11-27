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
    val site: Site? = null,
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
        defaultEnvironment = config["default"]?.map?.let { Environment(it) },
        productionEnvironment = config["production"]?.map?.let { Environment(it) },
        developmentEnvironment = config["development"]?.map?.let { Environment(it) },
        site = config["site"]?.string?.let { Utils.parseSite(it) },
        inProduction = config["inProduction"]?.boolean,
        initialConfigUrl = config["initialConfigUrl"]?.string,
        urlAllowList = config["urlAllowList"]?.list?.mapNotNull { it.string },
        urlAllowListScopeJavaScriptInterface = config["urlAllowListScopeJavaScriptInterface"]?.list?.mapNotNull { it.string },
        urlAllowListScopeOpenUrl = config["urlAllowListScopeOpenUrl"]?.list?.mapNotNull { it.string },
        isChannelCaptureEnabled = config["isChannelCaptureEnabled"]?.boolean,
        isChannelCreationDelayEnabled = config["isChannelCreationDelayEnabled"]?.boolean,
        enabledFeatures = config["enabledFeatures"]?.let { Utils.parseFeatures(it) },
        autoPauseInAppAutomationOnLaunch = config["autoPauseInAppAutomationOnLaunch"]?.boolean,
        androidConfig = config["android"]?.map?.let { Android(it) }
    )

    override fun toJsonValue(): JsonValue {
        return JsonMap.newBuilder()
            .put("default", defaultEnvironment)
            .put("production", productionEnvironment)
            .put("development", developmentEnvironment)
            .put("site", site?.let { site.name })
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
        val appKey: String?, val appSecret: String?, val logLevel: AirshipConfigOptions.LogLevel?
    ) : JsonSerializable {

        override fun toJsonValue(): JsonValue = JsonMap.newBuilder()
            .putOpt("appKey", appKey)
            .putOpt("appSecret", appSecret)
            .putOpt("logLevel", logLevel?.let { Utils.logLevelString(it) })
            .build()
            .toJsonValue()

        public constructor(config: JsonMap) : this(appKey = config["appKey"]?.string,
            appSecret = config["appSecret"]?.string,
            logLevel = config["logLevel"]?.string?.let { Utils.parseLogLevel(it) })
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
            appStoreUri = config["appStoreUri"]?.string,
            fcmFirebaseAppName = config["fcmFirebaseAppName"]?.string,
            notificationConfig = config["notificationConfig"]?.map?.let { NotificationConfig(it) },
            logPrivacyLevel = config["logPrivacyLevel"]?.string?.let { Utils.parseLogPrivacyLevel(it) }
        )
    }
}
