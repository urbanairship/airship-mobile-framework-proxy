package com.urbanairship.android.framework.proxy

import android.util.Log
import com.urbanairship.json.JsonException
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue

public data class ProxyConfig(
    val defaultEnvironment: Environment?,
    val productionEnvironment: Environment?,
    val developmentEnvironment: Environment?,
    val inProduction: Boolean?,
    val site: String?,
    val isChannelCreationDelayEnabled: Boolean?,
    val channelCaptureEnabled: Boolean?,
    val initialConfigUrl: String?,
//    val androidConfig: Android?,
    val suppressAllowListError: Boolean?,
    val urlAllowList: List<String>?,
    val urlAllowListScopeJavaScriptInterface: List<String>?,
    val urlAllowListScopeOpenUrl: List<String>?
) : JsonSerializable {
//
//    public constructor(config: JsonMap): this(
//        defaultEnvironment = config.get("default")?.map?.let { Environment(it) },
//
//    )
//        this.defaultEnvironment =
//
//        this.productionEnvironment: Environment? =
//            config.get("production")?.map?.let { Environment(it) }
//        this.developmentEnvironment: Environment? =
//            config.get("development")?.map?.let { Environment(it) }
//        this.inProduction: Boolean? = config.get("inProduction")?.boolean
//        this.site: String? = config.get("site")?.string
//        this.isChannelCreationDelayEnabled: Boolean? =
//            config.get("isChannelCreationDelayEnabled")?.boolean
//        val channelCaptureEnabled: Boolean? = config.get("isChannelCaptureEnabled")?.boolean
//        val initialConfigUrl: String? = config.get("initialConfigUrl")?.string
//        val androidConfig: Android? = config.get("android")?.map?.let { Android(it) }
//        val suppressAllowListError: Boolean? = config.get("suppressAllowListError")?.boolean
//        val urlAllowList: List<String>? = config.get("urlAllowList")?.list?.mapNotNull { it.string }
//        val urlAllowListScopeJavaScriptInterface: List<String>? =
//            config.get("urlAllowListScopeJavaScriptInterface")?.list?.mapNotNull { it.string }
//        val urlAllowListScopeOpenUrl: List<String>? =
//            config.get("urlAllowListScopeOpenUrl")?.list?.mapNotNull { it.string }
//
//    }
//

    override fun toJsonValue(): JsonValue {
        return JsonMap.newBuilder()
            .put("default", defaultEnvironment)
            .put("production", productionEnvironment)
            .put("development", developmentEnvironment)
            .putOpt("inProduction", inProduction)
            .put("default", defaultEnvironment)
            .build()
            .toJsonValue()
    }

    public data class Environment(
        val appKey: String?,
        val appSecret: String?,
        val logLevel: Int?
    ) : JsonSerializable {

        override fun toJsonValue(): JsonValue =
            JsonMap.newBuilder()
                .putOpt("appKey", appKey)
                .putOpt("appSecret", appSecret)
                .putOpt("logLevel", logLevel?.let { logLevelString(it) })
                .build()
                .toJsonValue()

        public constructor(config: JsonMap) : this(
            appKey = config.get("appKey")?.string,
            appSecret = config.get("appSecret")?.string,
            logLevel = config.get("logLevel")?.string?.let { parseLogLevel(it) }
        )
    }

    public data class Android(
        val appStoreUri: String?,
        val fcmFirebaseAppName: String?,
        val notificationConfig: NotificationConfig?
    ) : JsonSerializable {

        override fun toJsonValue(): JsonValue =
            JsonMap.newBuilder()
                .putOpt("appStoreUri", appStoreUri)
                .putOpt("fcmFirebaseAppName", fcmFirebaseAppName)
                .putOpt("notificationConfig", notificationConfig)
                .build()
                .toJsonValue()

        internal constructor(config: JsonMap): this(
            appStoreUri = config.get("appStoreUri")?.string,
            fcmFirebaseAppName = config.get("fcmFirebaseAppName")?.string,
            notificationConfig = config.get("notificationConfig")?.map?.let { NotificationConfig(it) }
        )
    }
    

    private companion object {
        private fun parseLogLevel(logLevel: String): Int {
            when (logLevel.lowercase().trim()) {
                "verbose" -> return Log.VERBOSE
                "debug" -> return Log.DEBUG
                "info" -> return Log.INFO
                "warning" -> return Log.WARN
                "error" -> return Log.ERROR
                "none" -> return Log.ASSERT
            }
            throw JsonException("Invalid log level: $logLevel")
        }

        private fun logLevelString(logLevel: Int): Int {
            when (logLevel) {
                Log.VERBOSE -> "verbose"
                Log.DEBUG -> "debug"
                Log.INFO -> "info"
                Log.WARN -> "warning"
                Log.ERROR -> "error"
                Log.ASSERT -> "none"
            }

            throw JsonException("Invalid log level: $logLevel")
        }
    }
}
