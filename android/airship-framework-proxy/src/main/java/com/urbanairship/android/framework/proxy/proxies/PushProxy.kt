package com.urbanairship.android.framework.proxy.proxies

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationManagerCompat
import com.urbanairship.android.framework.proxy.BaseNotificationProvider
import com.urbanairship.android.framework.proxy.NotificationConfig
import com.urbanairship.android.framework.proxy.NotificationStatus
import com.urbanairship.android.framework.proxy.ProxyLogger
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.android.framework.proxy.Utils
import com.urbanairship.json.JsonException
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf
import com.urbanairship.json.optionalField
import com.urbanairship.permission.Permission
import com.urbanairship.permission.PermissionPromptFallback
import com.urbanairship.permission.PermissionsManager
import com.urbanairship.push.PushManager
import com.urbanairship.push.PushMessage
import kotlin.coroutines.suspendCoroutine

public interface SuspendingPredicate<T> {
    public suspend fun apply(value: T): Boolean
}

public class PushProxy internal constructor(
    private val context: Context,
    private val store: ProxyStore,
    private val permissionsManagerProvider: () -> PermissionsManager,
    private val pushProvider: () -> PushManager
) {
    public var foregroundNotificationDisplayPredicate: SuspendingPredicate<Map<String, Any>>? = null

    public var isForegroundNotificationsEnabled: Boolean
        get() = store.isForegroundNotificationsEnabled
        set(enabled) { store.isForegroundNotificationsEnabled = enabled }

    public fun setNotificationConfig(config: JsonValue) {
        setNotificationConfig(NotificationConfig(config.optMap()))
    }

    public fun setNotificationConfig(config: NotificationConfig) {
        this.store.notificationConfig = config
    }

    public fun setUserNotificationsEnabled(enabled: Boolean) {
        pushProvider().userNotificationsEnabled = enabled
    }

    public suspend fun enableUserPushNotifications(args: EnableUserNotificationsArgs? = null): Boolean {
        return suspendCoroutine { continuation ->
            pushProvider().enableUserNotifications(promptFallback = args?.fallback ?: PermissionPromptFallback.None) { result ->
                continuation.resumeWith(Result.success(result))
            }
        }
    }

    public suspend fun getNotificationStatus(): NotificationStatus {
        val permissionStatus = permissionsManagerProvider().checkPermissionStatus(Permission.DISPLAY_NOTIFICATIONS)
        return NotificationStatus(
            pushProvider().pushNotificationStatus,
            permissionStatus.value
        )
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    public fun isNotificationChannelEnabled(channelId: String): Boolean {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = manager.getNotificationChannel(channelId)
        return if (channel == null) {
            false
        } else {
            channel.importance != NotificationManager.IMPORTANCE_NONE
        }
    }

    public fun getRegistrationToken(): String? {
        return pushProvider().pushToken
    }

    public fun isUserNotificationsEnabled(): Boolean {
        return pushProvider().userNotificationsEnabled
    }

    public fun clearNotifications() {
        NotificationManagerCompat.from(context).cancelAll()
    }

    public fun clearNotification(identifier: String) {
        if (identifier.isEmpty()) {
            ProxyLogger.error("Invalid identifier: $identifier")
            return
        }

        val parts = identifier.split(":".toRegex(), 2).toTypedArray()
        if (parts.isEmpty()) {
            ProxyLogger.error("Invalid identifier: $identifier")
            return
        }

        var tag: String? = null
        val id: Int = try {
            parts[0].toInt()
        } catch (e: NumberFormatException) {
            ProxyLogger.error(e, "Invalid identifier: $identifier")
            return
        }
        if (parts.size == 2) {
            tag = parts[1]
        }
        NotificationManagerCompat.from(context).cancel(tag, id)
    }

    public fun getActiveNotifications(): List<Map<String, Any>> {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        return manager.activeNotifications.mapNotNull { notification ->
            val id = notification.id
            val tag = notification.tag
            val pushBundle = notification.notification.extras
                .getBundle(BaseNotificationProvider.PUSH_MESSAGE_BUNDLE_EXTRA)

            if (pushBundle != null) {
                Utils.notificationMap(PushMessage(pushBundle), id, tag)
            } else {
                null
            }
        }
    }
}

public data class EnableUserNotificationsArgs(
    val fallback: PermissionPromptFallback?,
) : JsonSerializable {

    public override fun toJsonValue(): JsonValue = jsonMapOf("fallback" to fallback).toJsonValue()

    public companion object {
        @Throws(JsonException::class)
        public fun fromJson(value: JsonValue): EnableUserNotificationsArgs {
            val fallback = value.optMap().optionalField<String>("fallback")?.let {
                if ("systemSettings".equals(it, true)) {
                    PermissionPromptFallback.SystemSettings
                } else {
                    PermissionPromptFallback.None
                }
            }
            return EnableUserNotificationsArgs(fallback = fallback)
        }
    }
}
