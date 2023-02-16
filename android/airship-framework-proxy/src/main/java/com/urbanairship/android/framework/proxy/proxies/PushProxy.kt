package com.urbanairship.android.framework.proxy.proxies

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationManagerCompat
import com.urbanairship.PendingResult
import com.urbanairship.android.framework.proxy.BaseNotificationProvider
import com.urbanairship.android.framework.proxy.NotificationConfig
import com.urbanairship.android.framework.proxy.ProxyLogger
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.android.framework.proxy.Utils
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.permission.Permission
import com.urbanairship.permission.PermissionStatus
import com.urbanairship.permission.PermissionsManager
import com.urbanairship.push.PushManager
import com.urbanairship.push.PushMessage

public interface SuspendingPredicate<T> {
    public suspend fun apply(value: T): Boolean
}


public class PushProxy internal constructor(
    private val context: Context,
    private val store: ProxyStore,
    private val permissionsManagerProvider: () -> PermissionsManager,
    private val pushProvider: () -> PushManager
) {

    public val foregroundNotificationDisplayPredicate: SuspendingPredicate<Map<String, Any>>? = null

    public fun setNotificationConfig(config: JsonValue) {
        setNotificationConfig(NotificationConfig(config.optMap()))
    }

    public fun setNotificationConfig(config: NotificationConfig) {
        this.store.notificationConfig = config
    }

    public fun setUserNotificationsEnabled(enabled: Boolean) {
        pushProvider().userNotificationsEnabled = enabled
    }

    public fun enableUserPushNotifications(): PendingResult<Boolean> {
        val pending: PendingResult<Boolean> = PendingResult()
        permissionsManagerProvider().requestPermission(
            Permission.DISPLAY_NOTIFICATIONS,
            true
        ) { result ->
            pending.result = (result.permissionStatus == PermissionStatus.GRANTED)
        }
        return pending
    }

    public fun getNotificationStatus(): NotificationStatus {
        return NotificationStatus(
            pushProvider().isOptIn,
            pushProvider().userNotificationsEnabled,
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        )
    }

    public data class NotificationStatus(
        public val airshipOptIn: Boolean,
        public val airshipEnabled: Boolean,
        public val systemEnabled: Boolean
    ) : JsonSerializable {
        override fun toJsonValue(): JsonValue = JsonMap.newBuilder()
            .putOpt("airshipOptIn", airshipOptIn)
            .putOpt("airshipEnabled", airshipEnabled)
            .putOpt("systemEnabled", systemEnabled)
            .build()
            .toJsonValue()
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
            ProxyLogger.error("Invalid identifier: $identifier")
            return
        }
        if (parts.size == 2) {
            tag = parts[1]
        }
        NotificationManagerCompat.from(context).cancel(tag, id)
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
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

