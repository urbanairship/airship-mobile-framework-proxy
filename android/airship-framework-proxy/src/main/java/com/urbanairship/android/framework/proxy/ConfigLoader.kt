package com.urbanairship.android.framework.proxy

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.util.Log
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.PrivacyManager
import com.urbanairship.json.JsonList
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonValue

internal class ConfigLoader {

    internal companion object {
        const val NOTIFICATION_ICON_KEY = "icon"
        const val NOTIFICATION_LARGE_ICON_KEY = "largeIcon"
        const val ACCENT_COLOR_KEY = "accentColor"
        const val DEFAULT_CHANNEL_ID_KEY = "defaultChannelId"
    }

    @SuppressLint("RestrictedApi")
    internal fun loadConfig(context: Context): AirshipConfigOptions {
        val builder = AirshipConfigOptions.newBuilder()
            .applyDefaultProperties(context)
            .setRequireInitialRemoteConfigEnabled(true)

        val config: JsonMap? = ProxyStore.shared(context).airshipConfig
        if (config == null || config.isEmpty) {
            return builder.build()
        }

        val developmentEnvironment = config.opt("development").map
        val productionEnvironment = config.opt("production").map
        val defaultEnvironment = config.opt("default").map

        developmentEnvironment?.let {
            builder.setDevelopmentAppKey(it.opt("appKey").string)
                .setDevelopmentAppSecret(it.opt("appSecret").string)
            val logLevel = it.opt("logLevel").string
            logLevel?.let { logLvl ->
                builder.setLogLevel(convertLogLevel(logLvl, Log.DEBUG))
            }
        }

        productionEnvironment?.let {
            builder.setProductionAppKey(it.opt("appKey").string)
                .setProductionAppSecret(it.opt("appSecret").string)
            val logLevel = it.opt("logLevel").string
            logLevel?.let { logLvl ->
                builder.setProductionLogLevel(convertLogLevel(logLvl, Log.ERROR))
            }
        }

        defaultEnvironment?.let {
            builder.setAppKey(it.opt("appKey").string)
                .setAppSecret(it.opt("appSecret").string)
            val logLevel = it.opt("logLevel").string
            logLevel?.let { logLvl ->
                builder.setLogLevel(convertLogLevel(logLvl, Log.ERROR))
            }
        }

        val site = config.opt("site").string
        site?.let {
            try {
                builder.setSite(parseSite(it))
            } catch (e: Exception) {
                ProxyLogger.error("Invalid site $it", e)
            }
        }

        if (config.containsKey("inProduction")) {
            builder.setInProduction(config.opt("inProduction").getBoolean(false))
        }

        if (config.containsKey("isChannelCreationDelayEnabled")) {
            builder.setChannelCreationDelayEnabled(
                config.opt("isChannelCreationDelayEnabled").getBoolean(false)
            )
        }

        val initialConfigUrl = config.opt("initialConfigUrl").string
        initialConfigUrl?.let {
            try {
                builder.setInitialConfigUrl(initialConfigUrl)
            } catch (e: Exception) {
                ProxyLogger.error("Invalid initialConfigUrl $it", e)
            }
        }

        val urlAllowList = parseArray(config.opt("urlAllowList"))
        urlAllowList?.let {
            builder.setUrlAllowList(it)
        }

        val urlAllowListScopeJavaScriptInterface =
            parseArray(config.opt("urlAllowListScopeJavaScriptInterface"))
        urlAllowListScopeJavaScriptInterface?.let {
            builder.setUrlAllowListScopeJavaScriptInterface(it)
        }

        val urlAllowListScopeOpenUrl = parseArray(config.opt("urlAllowListScopeOpenUrl"))
        urlAllowListScopeOpenUrl?.let {
            builder.setUrlAllowListScopeOpenUrl(it)
        }

        val chat = config.opt("chat").map
        chat?.let {
            builder.setChatSocketUrl(it.opt("webSocketUrl").optString())
                .setChatUrl(it.opt("url").optString())
        }

        val android = config.opt("android").map
        android?.let {
            if (it.containsKey("appStoreUri")) {
                builder.setAppStoreUri(Uri.parse(it.opt("appStoreUri").optString()))
            }

            if (it.containsKey("fcmFirebaseAppName")) {
                builder.setFcmFirebaseAppName(it.opt("fcmFirebaseAppName").optString())
            }

            if (it.containsKey("notificationConfig")) {
                applyNotificationConfig(context, it.opt("notificationConfig").optMap(), builder)
            }
        }

        val enabledFeatures = config.opt("enabledFeatures").list
        try {
            enabledFeatures?.let {
                builder.setEnabledFeatures(parseFeatures(it))
            }
        } catch (e: Exception) {
            ProxyLogger.error("Invalid enabled features: $enabledFeatures")
        }
        return builder.build()
    }

    private fun applyNotificationConfig(
        context: Context,
        notificationConfig: JsonMap,
        builder: AirshipConfigOptions.Builder
    ) {
        val icon = notificationConfig.opt(NOTIFICATION_ICON_KEY).string
        icon?.let {
            val resourceId = Utils.getNamedResource(context, it, "drawable")
            builder.setNotificationIcon(resourceId)
        }

        val largeIcon =
            notificationConfig.opt(NOTIFICATION_LARGE_ICON_KEY).string
        largeIcon?.let {
            val resourceId = Utils.getNamedResource(context, it, "drawable")
            builder.setNotificationLargeIcon(resourceId)
        }

        val accentColor = notificationConfig.opt(ACCENT_COLOR_KEY).string
        accentColor?.let {
            builder.setNotificationAccentColor(Utils.getHexColor(it, 0))
        }

        val channelId =
            notificationConfig.opt(DEFAULT_CHANNEL_ID_KEY).string
        channelId?.let {
            builder.setNotificationChannel(it)
        }
    }

    @PrivacyManager.Feature
    private fun parseFeatures(jsonList: JsonList): Int {
        var result = PrivacyManager.FEATURE_NONE
        for (value in jsonList) {
            result = result or Utils.parseFeature(value.optString())
        }
        return result
    }

    @AirshipConfigOptions.Site
    private fun parseSite(value: String): String {
        when (value) {
            "eu" -> return AirshipConfigOptions.SITE_EU
            "us" -> return AirshipConfigOptions.SITE_US
        }
        throw IllegalArgumentException("Invalid site: $value")
    }

    private fun convertLogLevel(logLevel: String, defaultValue: Int): Int {
        when (logLevel) {
            "verbose" -> return Log.VERBOSE
            "debug" -> return Log.DEBUG
            "info" -> return Log.INFO
            "warning" -> return Log.WARN
            "error" -> return Log.ERROR
            "none" -> return Log.ASSERT
        }
        return defaultValue
    }

    private fun parseArray(value: JsonValue?): Array<String?>? {
        if (value == null || !value.isJsonList) {
            return null
        }

        val result = arrayOfNulls<String>(value.optList().size())
        for (i in 0 until value.optList().size()) {
            val string = value.optList()[i].string
            if (string == null) {
                ProxyLogger.error("Invalid string array: $value")
                return null
            }
            result[i] = string
        }
        return result
    }
}
