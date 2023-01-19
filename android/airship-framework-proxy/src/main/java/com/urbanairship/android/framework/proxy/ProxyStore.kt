/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.annotation.SuppressLint
import android.content.Context
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue

/**
 * Stores shared preferences and checks preference-dependent state.
 */
public class ProxyStore internal constructor(private val context: Context) {

    private val preferences by lazy {
        context.getSharedPreferences(SHARED_PREFERENCES_FILE, Context.MODE_PRIVATE)
    }

    private var _notificationConfig: NotificationConfig? = null
    public var notificationConfig: NotificationConfig?
        get() {
            val config = _notificationConfig
            if (config != null) {
                return config
            }

            val fromStore = getJson(NOTIFICATION_CONFIG) { NotificationConfig(it.optMap()) }
            _notificationConfig = fromStore
            return fromStore
        }
        set(value) = setJson(NOTIFICATION_CONFIG, value)

    public var airshipConfig: ProxyConfig?
        get() = getJson(AIRSHIP_CONFIG) { ProxyConfig(it.optMap())}
        set(value) = setJson(AIRSHIP_CONFIG, value)

    public  var optInStatus: Boolean
        get() = getBoolean(NOTIFICATIONS_OPT_IN, false)
        set(optIn) = setBoolean(NOTIFICATIONS_OPT_IN, optIn)

    public var isAutoLaunchMessageCenterEnabled: Boolean
        get() = getBoolean(AUTO_LAUNCH_MESSAGE_CENTER, true)
        set(enabled) = setBoolean(AUTO_LAUNCH_MESSAGE_CENTER, enabled)

    public fun isAutoLaunchPreferenceCenterEnabled(preferenceId: String): Boolean {
        val key = getAutoLaunchPreferenceCenterKey(preferenceId)
        return getBoolean(key, true)
    }

    public fun setAutoLaunchPreferenceCenter(preferenceId: String, autoLaunch: Boolean) {
        val key = getAutoLaunchPreferenceCenterKey(preferenceId)
        setBoolean(key, autoLaunch)
    }

    private fun <T> getJson(key: String, parser: (JsonValue) -> T): T? {
        val jsonString = getString(NOTIFICATION_CONFIG, null) ?: return null
        return try {
            val json = JsonValue.parseString(jsonString)
            parser(json)
        } catch (e: Exception) {
            ProxyLogger.error("Failed to parse $key in config.", e)
            null
        }
    }

    private fun getString(key: String, defaultValue: String?): String? {
        return preferences.getString(key, defaultValue)
    }

    private fun getBoolean(key: String, defaultValue: Boolean): Boolean {
        return preferences.getBoolean(key, defaultValue)
    }

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

    private fun getAutoLaunchPreferenceCenterKey(preferenceId: String): String {
        return "${PREFERENCE_CENTER_AUTO_LAUNCH_PREFIX}_${preferenceId}"
    }

    internal companion object {
        private const val SHARED_PREFERENCES_FILE = "com.urbanairship.android.framework.proxy"
        private const val NOTIFICATIONS_OPT_IN = "NOTIFICATIONS_OPT_IN"
        private const val AUTO_LAUNCH_MESSAGE_CENTER = "AUTO_LAUNCH_MESSAGE_CENTER"
        private const val AIRSHIP_CONFIG = "AIRSHIP_CONFIG"
        private const val NOTIFICATION_CONFIG = "NOTIFICATION_CONFIG"
        private const val PREFERENCE_CENTER_AUTO_LAUNCH_PREFIX = "PREFERENCE_CENTER_AUTO_LAUNCH"

        @SuppressLint("StaticFieldLeak")
        @Volatile
        private var sharedInstance: ProxyStore? = null
        private val sharedInstanceLock = Any()

        fun shared(context: Context): ProxyStore {
            synchronized(sharedInstanceLock) {
                if (sharedInstance == null) {
                    sharedInstance = ProxyStore(context)
                }
                return sharedInstance!!
            }
        }
    }
}