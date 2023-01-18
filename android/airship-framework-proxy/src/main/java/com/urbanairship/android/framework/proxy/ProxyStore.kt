/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import androidx.preference.PreferenceManager
import com.urbanairship.json.JsonException
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue

/**
 * Stores shared preferences and checks preference-dependent state.
 */
internal class ProxyStore(private val context: Context) {

    private val preferences by lazy {
        context.getSharedPreferences(SHARED_PREFERENCES_FILE, Context.MODE_PRIVATE)
    }

    private val lock = Object()

    private var _notificationConfig: NotificationConfig? = null
    var notificationConfig: NotificationConfig
        get() {
            val config = _notificationConfig
            if (config != null) {
                return config
            }

            val fromJson = NotificationConfig(getJson(NOTIFICATION_CONFIG).optMap())
            _notificationConfig = fromJson
            return fromJson
        }
        set(value) = setJson(NOTIFICATION_CONFIG, value)

    /**
     * Airship Configuration.
     */
    var airshipConfig: JsonMap?
        get() = getJson(AIRSHIP_CONFIG).optMap()
        set(value) =  setJson(AIRSHIP_CONFIG, value)

    var optInStatus: Boolean
        get() = getBoolean(NOTIFICATIONS_OPT_IN, false)
        set(optIn) = setBoolean(NOTIFICATIONS_OPT_IN, optIn)

    var isAutoLaunchMessageCenterEnabled: Boolean
        get() = getBoolean(AUTO_LAUNCH_MESSAGE_CENTER, true)
        set(enabled) = setBoolean(AUTO_LAUNCH_MESSAGE_CENTER, enabled)

    fun isAutoLaunchPreferenceCenterEnabled(preferenceId: String): Boolean {
        val key = getAutoLaunchPreferenceCenterKey(preferenceId)
        return getBoolean(key, true)
    }

    fun setAutoLaunchPreferenceCenter(preferenceId: String, autoLaunch: Boolean) {
        val key = getAutoLaunchPreferenceCenterKey(preferenceId)
        setBoolean(key, autoLaunch)
    }

    private fun getJson(key: String, defaultValue: JsonValue = JsonValue.NULL): JsonValue {
        ensurePreferences()
        val jsonString = getString(NOTIFICATION_CONFIG, null) ?: return defaultValue
        return try {
            return JsonValue.parseString(jsonString)
        } catch (e: JsonException) {
            ProxyLogger.error("Failed to parse $key in config.", e)
            defaultValue
        }
    }

    private fun getString(key: String, defaultValue: String?): String? {
        ensurePreferences()
        return preferences.getString(key, defaultValue)
    }

    private fun getBoolean(key: String, defaultValue: Boolean): Boolean {
        ensurePreferences()
        return preferences.getBoolean(key, defaultValue)
    }

    private fun setString(key: String, value: String?) {
        ensurePreferences()
        if (value != null) {
            preferences.edit().putString(key, value).apply()
        } else {
            preferences.edit().remove(key).apply()
        }
    }

    private fun setBoolean(key: String, value: Boolean?) {
        ensurePreferences()
        if (value != null) {
            preferences.edit().putBoolean(key, value).apply()
        } else {
            preferences.edit().remove(key).apply()
        }
    }

    private fun setJson(key: String, value: JsonSerializable?) {
        ensurePreferences()
        if (value != null) {
            preferences.edit().putString(key, value.toJsonValue().toString()).apply()
        } else {
            preferences.edit().remove(key).apply()
        }
    }

    private fun ensurePreferences() {
        synchronized (lock) {
            // Migrate any data stored in default
            val defaultPreferences = PreferenceManager.getDefaultSharedPreferences(context)
            if (defaultPreferences.contains(AUTO_LAUNCH_MESSAGE_CENTER)) {
                val autoLaunchMessageCenter = defaultPreferences.getBoolean(AUTO_LAUNCH_MESSAGE_CENTER, true)
                defaultPreferences.edit().remove(AUTO_LAUNCH_MESSAGE_CENTER).apply()
                preferences.edit().putBoolean(AUTO_LAUNCH_MESSAGE_CENTER, autoLaunchMessageCenter).apply()
            }
        }
    }

    private fun getAutoLaunchPreferenceCenterKey(preferenceId: String): String {
        return "preference_center_auto_launch_$preferenceId"
    }

    companion object {
        @SuppressLint("StaticFieldLeak")
        @Volatile
        private var sharedInstance: ProxyStore? = null
        private val sharedInstanceLock = Any()

        private const val SHARED_PREFERENCES_FILE = "com.urbanairship.android.framework.proxy"
        private const val NOTIFICATIONS_OPT_IN = "NOTIFICATIONS_OPT_IN"
        private const val AUTO_LAUNCH_MESSAGE_CENTER = "AUTO_LAUNCH_MESSAGE_CENTER"
        private const val AIRSHIP_CONFIG = "AIRSHIP_CONFIG"
        private const val NOTIFICATION_CONFIG = "NOTIFICATION_CONFIG"

        /**
         * Returns the shared [ProxyStore] instance.
         *
         * @return The shared [ProxyStore] instance.
         */
        @JvmStatic
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