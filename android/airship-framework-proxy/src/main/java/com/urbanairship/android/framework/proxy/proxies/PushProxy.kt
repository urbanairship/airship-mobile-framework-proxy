package com.urbanairship.android.framework.proxy.proxies

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationManagerCompat
import com.urbanairship.PendingResult
import com.urbanairship.actions.ActionRunRequest
import com.urbanairship.actions.PermissionResultReceiver
import com.urbanairship.actions.PromptPermissionAction
import com.urbanairship.android.framework.proxy.BaseNotificationProvider
import com.urbanairship.android.framework.proxy.NotificationConfig
import com.urbanairship.android.framework.proxy.NotificationStatus
import com.urbanairship.android.framework.proxy.ProxyLogger
import com.urbanairship.android.framework.proxy.ProxyStore
import com.urbanairship.android.framework.proxy.Utils
import com.urbanairship.android.framework.proxy.proxies.EnableUserNotificationsArgs.Fallback.entries
import com.urbanairship.android.framework.proxy.suspendingPermissionCheck
import com.urbanairship.json.JsonException
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf
import com.urbanairship.permission.Permission
import com.urbanairship.permission.PermissionStatus
import com.urbanairship.permission.PermissionsManager
import com.urbanairship.push.PushManager
import com.urbanairship.push.PushMessage
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flow
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

public interface SuspendingPredicate<T> {
    public suspend fun apply(value: T): Boolean
}

public data class EnableUserNotificationsArgs(
    val fallback: Fallback?,
) : JsonSerializable {

    public override fun toJsonValue(): JsonValue = jsonMapOf("fallback" to fallback).toJsonValue()

    public companion object {
        @Throws(JsonException::class)
        public fun fromJson(value: JsonValue): EnableUserNotificationsArgs {
            return EnableUserNotificationsArgs(fallback = value.optMap().get("fallback")?.let { Fallback.fromJson(it) })
        }
    }

    public enum class Fallback(internal val jsonValue: String) : JsonSerializable {
        SYSTEM_SETTINGS("systemSettings");

        override fun toJsonValue(): JsonValue = JsonValue.wrap(jsonValue)

        internal companion object {
            @Throws(JsonException::class)
            fun fromJson(value: JsonValue): Fallback {
                return try {
                    entries.first { it.jsonValue == value.requireString() }
                } catch (ex: NoSuchElementException) {
                    throw JsonException("Invalid fallback $value", ex)
                }
            }
        }
    }
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
        // Make sure push is available
        pushProvider()

        // Using the prompt permission action as a workaround until SDK is able
        // to do this natively
        val fallbackSystemSettings = args?.fallback == EnableUserNotificationsArgs.Fallback.SYSTEM_SETTINGS

        val result = suspendCoroutine { continuation ->
            ActionRunRequest.createRequest(PromptPermissionAction.DEFAULT_REGISTRY_NAME).setValue(
                jsonMapOf(
                    PromptPermissionAction.ENABLE_AIRSHIP_USAGE_ARG_KEY to false,
                    PromptPermissionAction.PERMISSION_ARG_KEY to Permission.DISPLAY_NOTIFICATIONS,
                    PromptPermissionAction.FALLBACK_SYSTEM_SETTINGS_ARG_KEY to fallbackSystemSettings
                )
            ).setMetadata(Bundle().apply {
                putParcelable(
                    PromptPermissionAction.RECEIVER_METADATA,
                    object : PermissionResultReceiver(Handler(Looper.getMainLooper())) {
                        override fun onResult(
                            permission: Permission,
                            before: PermissionStatus,
                            after: PermissionStatus
                        ) {
                            continuation.resume(after == PermissionStatus.GRANTED)
                        }
                    })
            }).run()
        }

        // Enable user notifications flag regardless of status. Remove this once
        // we have a native SDK call.
        setUserNotificationsEnabled(true)

        return result
    }

    public suspend fun getNotificationStatus(): NotificationStatus {
        val permissionStatus = permissionsManagerProvider().suspendingPermissionCheck(Permission.DISPLAY_NOTIFICATIONS)
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

