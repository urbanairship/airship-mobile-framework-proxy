/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import androidx.annotation.ColorInt
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.PrivacyManager
import com.urbanairship.android.framework.proxy.ProxyLogger.error
import com.urbanairship.json.JsonException
import com.urbanairship.json.JsonValue
import com.urbanairship.push.PushMessage
import com.urbanairship.util.UAStringUtil
import androidx.core.graphics.toColorInt

/**
 * Module utils.
 */
public object Utils {

    public fun parseLogLevel(logLevel: String): AirshipConfigOptions.LogLevel {
        return when (logLevel.lowercase().trim()) {
            "verbose" -> AirshipConfigOptions.LogLevel.VERBOSE
            "debug" -> AirshipConfigOptions.LogLevel.DEBUG
            "info" -> AirshipConfigOptions.LogLevel.INFO
            "warning" -> AirshipConfigOptions.LogLevel.WARN
            "error" -> AirshipConfigOptions.LogLevel.ERROR
            "none" -> AirshipConfigOptions.LogLevel.ASSERT
            else -> {
                throw JsonException("Invalid log level: $logLevel")
            }
        }
    }

    public fun logLevelString(logLevel: AirshipConfigOptions.LogLevel): String {
        return when (logLevel) {
            AirshipConfigOptions.LogLevel.VERBOSE -> "verbose"
            AirshipConfigOptions.LogLevel.DEBUG -> "debug"
            AirshipConfigOptions.LogLevel.INFO -> "info"
            AirshipConfigOptions.LogLevel.WARN -> "warning"
            AirshipConfigOptions.LogLevel.ERROR -> "error"
            AirshipConfigOptions.LogLevel.ASSERT -> "none"
        }
    }

    public fun parseLogPrivacyLevel(privacyLevel: String): AirshipConfigOptions.PrivacyLevel {
        return when (privacyLevel.lowercase().trim()) {
            "public" -> AirshipConfigOptions.PrivacyLevel.PUBLIC
            "private" -> AirshipConfigOptions.PrivacyLevel.PRIVATE
            else -> {
                throw JsonException("Invalid log privacy level: $privacyLevel")
            }
        }
    }

    public fun logPrivacyLevelString(privacyLevel: AirshipConfigOptions.PrivacyLevel): String {
        return when (privacyLevel) {
            AirshipConfigOptions.PrivacyLevel.PUBLIC -> "public"
            AirshipConfigOptions.PrivacyLevel.PRIVATE -> "private"
        }
    }

    public fun parseFeatures(value: JsonValue): PrivacyManager.Feature {
        if (value.isJsonList) {
            return PrivacyManager.Feature.fromJson(value) ?: PrivacyManager.Feature.NONE
        }
        return PrivacyManager.Feature.NONE
    }

    public fun parseSite(value: String): AirshipConfigOptions.Site {
        return when (value.lowercase()) {
            "eu" -> AirshipConfigOptions.Site.SITE_EU
            "us" -> AirshipConfigOptions.Site.SITE_US
            else -> {
                throw IllegalArgumentException("Invalid site: $value")
            }
        }
    }

    /**
     * Gets a resource value by name.
     *
     * @param context        The context.
     * @param resourceName   The resource name.
     * @param resourceFolder The resource folder.
     * @return The resource ID or 0 if not found.
     */
    @SuppressLint("DiscouragedApi")
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
                return hexColor.toColorInt()
            } catch (e: IllegalArgumentException) {
                error(e, "Unable to parse color: %s", hexColor)
            }
        }
        return defaultColor
    }

    @JvmStatic
    public fun featureNames(features: PrivacyManager.Feature): List<String> {
        return features.toJsonValue().optList().mapNotNull { it.string }
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
        for (key in message.getPushBundle().keySet()) {
            if ("android.support.content.wakelockid" == key) {
                continue
            }

            if ("google.sent_time" == key) {
                extras[key] = message.getPushBundle().getLong(key).toString()
                continue
            }
            if ("google.ttl" == key) {
                extras[key] = message.getPushBundle().getInt(key).toString()
                continue
            }
            val value = message.getPushBundle().getString(key)
            if (value != null) {
                extras[key] = value
            }
        }
        notification["extras"] = extras;

        message.title?.let { notification["title"] = it }
        message.alert?.let { notification["alert"] = it }
        message.summary?.let { notification["subtitle"] = it }
        notificationId?.let {
            notification["notificationId"] = getNotificationId(it, notificationTag)
        }

        return notification
    }
}
