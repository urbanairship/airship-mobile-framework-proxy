/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import android.graphics.Color
import android.util.Log
import androidx.annotation.ColorInt
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.PrivacyManager
import com.urbanairship.android.framework.proxy.ProxyLogger.error
import com.urbanairship.json.JsonException
import com.urbanairship.json.JsonValue
import com.urbanairship.push.PushMessage
import com.urbanairship.util.UAStringUtil

/**
 * Module utils.
 */
public object Utils {
    internal val featureMap: Map<String, Int> = mapOf(
        "none" to PrivacyManager.FEATURE_NONE,
        "in_app_automation" to PrivacyManager.FEATURE_IN_APP_AUTOMATION,
        "message_center" to PrivacyManager.FEATURE_MESSAGE_CENTER,
        "push" to PrivacyManager.FEATURE_PUSH,
        "chat" to PrivacyManager.FEATURE_CHAT,
        "analytics" to PrivacyManager.FEATURE_ANALYTICS,
        "tags_and_attributes" to PrivacyManager.FEATURE_TAGS_AND_ATTRIBUTES,
        "contacts" to PrivacyManager.FEATURE_CONTACTS,
        "location" to PrivacyManager.FEATURE_LOCATION,
        "all" to PrivacyManager.FEATURE_ALL
    )

    public fun parseLogLevel(logLevel: String): Int {
        return when (logLevel.lowercase().trim()) {
            "verbose" -> Log.VERBOSE
            "debug" -> Log.DEBUG
            "info" -> Log.INFO
            "warning" -> Log.WARN
            "error" -> Log.ERROR
            "none" -> Log.ASSERT
            else -> {
                throw JsonException("Invalid log level: $logLevel")
            }
        }
    }

    public fun logLevelString(logLevel: Int): String {
        return when (logLevel) {
            Log.VERBOSE -> "verbose"
            Log.DEBUG -> "debug"
            Log.INFO -> "info"
            Log.WARN -> "warning"
            Log.ERROR -> "error"
            Log.ASSERT -> "none"
            else -> {
                throw JsonException("Invalid log level: $logLevel")
            }
        }
    }

    @PrivacyManager.Feature
    public fun parseFeatures(value: JsonValue): Int {
        var result = PrivacyManager.FEATURE_NONE
        for (value in value.optList()) {
            result = result or parseFeature(value.optString())
        }
        return result
    }

    @AirshipConfigOptions.Site
    public fun parseSite(value: String): String {
        return when (value.lowercase()) {
            "eu" -> AirshipConfigOptions.SITE_EU
            "us" -> AirshipConfigOptions.SITE_US
            else -> {
                throw IllegalArgumentException("Invalid site: $value")
            }
        }
    }


    @AirshipConfigOptions.Site
    public fun siteString(site: String): String {
       return site.lowercase()
    }

    /**
     * Gets a resource value by name.
     *
     * @param context        The context.
     * @param resourceName   The resource name.
     * @param resourceFolder The resource folder.
     * @return The resource ID or 0 if not found.
     */
    @JvmStatic
    public fun getNamedResource(
        context: Context,
        resourceName: String,
        resourceFolder: String
    ): Int {
        if (!UAStringUtil.isEmpty(resourceName)) {
            val id =
                context.resources.getIdentifier(resourceName, resourceFolder, context.packageName)
            if (id != 0) {
                return id
            } else {
                error("Unable to find resource with name: %s", resourceName)
            }
        }
        return 0
    }

    /**
     * Gets a hex color as a color int.
     *
     * @param hexColor     The hex color.
     * @param defaultColor Default value if the conversion was not successful.
     * @return The color int.
     */
    @ColorInt
    @JvmStatic
    public fun getHexColor(hexColor: String, @ColorInt defaultColor: Int): Int {
        if (!UAStringUtil.isEmpty(hexColor)) {
            try {
                return Color.parseColor(hexColor)
            } catch (e: IllegalArgumentException) {
                error(e, "Unable to parse color: %s", hexColor)
            }
        }
        return defaultColor
    }

    @PrivacyManager.Feature
    @JvmStatic
    public fun parseFeature(feature: String): Int {
        val value = featureMap[feature]
        value?.let {
            return it
        }

        throw IllegalArgumentException("Invalid feature: $feature")
    }

    @JvmStatic
    public fun featureNames(@PrivacyManager.Feature features: Int): List<String> {
        val result: MutableList<String> = ArrayList()

        if (features == PrivacyManager.FEATURE_ALL) {
            return featureMap.keys.filter {
                it != "none" && it != "all"
            }.toList()
        }

        if (features == PrivacyManager.FEATURE_NONE) {
            return emptyList()
        }

        for ((key, value) in featureMap) {
            if (value == PrivacyManager.FEATURE_ALL) {
                continue
            }
            if (value == PrivacyManager.FEATURE_NONE) {
                continue
            }
            if (value and features == value) {
                result.add(key)
            }
        }
        return result
    }

    private fun getNotificationId(notificationId: Int, notificationTag: String?): String {
        var id = notificationId.toString()
        if (!UAStringUtil.isEmpty(notificationTag)) {
            id += ":$notificationTag"
        }
        return id
    }

    public fun notificationMap(
        message: PushMessage,
        notificationId: Int? = null,
        notificationTag: String? = null
    ): Map<String, Any> {

        val notification = mutableMapOf<String, Any>()
        val extras = mutableMapOf<String, String>()
        for (key in message.pushBundle.keySet()) {
            if ("android.support.content.wakelockid" == key) {
                continue
            }

            if ("google.sent_time" == key) {
                extras[key] = message.pushBundle.getLong(key).toString()
                continue
            }
            if ("google.ttl" == key) {
                extras[key] = message.pushBundle.getInt(key).toString()
                continue
            }
            val value = message.pushBundle.getString(key)
            if (value != null) {
                extras[key] = value
            }
        }
        notification["extras"] = extras;

        message.title?.let { notification["title"] = it }
        message.alert?.let { notification["alert"] = it }
        message.summary?.let { notification["summary"] = it }
        notificationId?.let {
            notification["notificationId"] = getNotificationId(it, notificationTag)
        }

        return notification
    }
}
