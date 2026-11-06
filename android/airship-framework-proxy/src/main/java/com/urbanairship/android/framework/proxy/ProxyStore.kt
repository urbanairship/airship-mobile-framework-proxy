/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import com.urbanairship.UALog
import com.urbanairship.android.framework.proxy.proxies.PushProxy
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf
import com.urbanairship.json.optionalField
import com.urbanairship.json.requireField
import com.urbanairship.push.PushNotificationStatus

/**
 * Stores shared preferences and checks preference-dependent state.
 */
public class ProxyStore internal constructor(private val context: Context) {

    private val preferences by lazy {
        context.getSharedPreferences(SHARED_PREFERENCES_FILE, Context.MODE_PRIVATE)
    }

    private val notificationConfigEntry = MemoizedJson(NOTIFICATION_CONFIG) { NotificationConfig(it.optMap()) }
    private val airshipConfigEntry = MemoizedJson(AIRSHIP_CONFIG) { ProxyConfig(it.optMap()) }
    private val notificationStatusEntry = MemoizedJson(NOTIFICATION_STATUS) { NotificationStatus(it) }

    public var notificationConfig: NotificationConfig?
        get() = notificationConfigEntry.get()
        set(value) = notificationConfigEntry.set(value)

    public var airshipConfig: ProxyConfig?
        get() = airshipConfigEntry.get()
        set(value) = airshipConfigEntry.set(value)

    public var lastNotificationStatus: NotificationStatus?
        get() = notificationStatusEntry.get()
        set(status) = notificationStatusEntry.set(status)

    public var defaultAutoLaunchMessageCenter: Boolean = true

    public var isAutoLaunchMessageCenterEnabled: Boolean
        get() = getBoolean(AUTO_LAUNCH_MESSAGE_CENTER, defaultAutoLaunchMessageCenter)
        set(enabled) = setBoolean(AUTO_LAUNCH_MESSAGE_CENTER, enabled)

    public var defaultForegroundNotificationsEnabled: Boolean = true
    public var isForegroundNotificationsEnabled: Boolean
        get() = getBoolean(FOREGROUND_NOTIFICATIONS, defaultForegroundNotificationsEnabled)
        set(enabled) = setBoolean(FOREGROUND_NOTIFICATIONS, enabled)

    public fun isAutoLaunchPreferenceCenterEnabled(preferenceId: String): Boolean {
        val key = getAutoLaunchPreferenceCenterKey(preferenceId)
        return getBoolean(key, true)
    }

    public fun setAutoLaunchPreferenceCenter(preferenceId: String, autoLaunch: Boolean) {
        val key = getAutoLaunchPreferenceCenterKey(preferenceId)
        setBoolean(key, autoLaunch)
    }

    private fun <T> getJson(key: String, parser: (JsonValue) -> T): T? {
        val jsonString = getString(key, null) ?: return null
        return try {
            val json = JsonValue.parseString(jsonString)
            parser(json)
        } catch (e: Exception) {
            UALog.e(e) { "Failed to parse $key in config." }
            null
        }
    }

    private fun getString(key: String, defaultValue: String?): String? = preferences.getString(key, defaultValue)

    private fun getBoolean(key: String, defaultValue: Boolean): Boolean = preferences.getBoolean(key, defaultValue)

    private fun setString(key: String, value: String?) {
        if (value != null) {
            preferences.edit().putString(key, value).apply()
        } else {
            preferences.edit().remove(key).apply()
        }
    }

    private fun setBoolean(key: String, value: Boolean?) {
        if (value != null) {
            preferences.edit().putBoolean(key, value).apply()
        } else {
            preferences.edit().remove(key).apply()
        }
    }

    private fun setJson(key: String, value: JsonSerializable?) {
        if (value != null) {
            preferences.edit().putString(key, value.toJsonValue().toString()).apply()
        } else {
            preferences.edit().remove(key).apply()
        }
    }

    private fun getAutoLaunchPreferenceCenterKey(preferenceId: String): String =
        "${PREFERENCE_CENTER_AUTO_LAUNCH_PREFIX}_$preferenceId"

    /**
     * Reads a JSON preference once and keeps the parsed value in memory.
     *
     * Writes refresh the memo, so a read always reflects the last write.
     *
     * @param key The preference key.
     * @param parser Parses the stored JSON into a value.
     */
    private inner class MemoizedJson<T : JsonSerializable>(
        private val key: String,
        private val parser: (JsonValue) -> T
    ) {
        private var cached: T? = null
        private var isLoaded: Boolean = false

        @Synchronized
        fun get(): T? {
            if (!isLoaded) {
                cached = getJson(key, parser)
                isLoaded = true
            }
            return cached
        }

        @Synchronized
        fun set(value: T?) {
            cached = value
            isLoaded = true
            setJson(key, value)
        }
    }

    internal companion object {
        private const val SHARED_PREFERENCES_FILE = "com.urbanairship.android.framework.proxy"
        private const val NOTIFICATION_STATUS = "NOTIFICATION_STATUS"
        private const val AUTO_LAUNCH_MESSAGE_CENTER = "AUTO_LAUNCH_MESSAGE_CENTER"
        private const val FOREGROUND_NOTIFICATIONS = "FOREGROUND_NOTIFICATIONS"

        private const val AIRSHIP_CONFIG = "AIRSHIP_CONFIG"
        private const val NOTIFICATION_CONFIG = "NOTIFICATION_CONFIG"
        private const val PREFERENCE_CENTER_AUTO_LAUNCH_PREFIX = "PREFERENCE_CENTER_AUTO_LAUNCH"
    }
}
