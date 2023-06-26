/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.push.PushNotificationStatus

/**
 * Notification status event.
 *
 * @param status The status.
 */
internal class NotificationStatusEvent(private val status: PushNotificationStatus) : Event {
    override val type = EventType.NOTIFICATION_STATUS_CHANGED
    override val body: Map<String, Any> = mapOf(
        "isUserNotificationsEnabled" to status.isUserNotificationsEnabled,
        "areNotificationsAllowed" to status.areNotificationsAllowed,
        "isPushPrivacyFeatureEnabled" to status.isPushPrivacyFeatureEnabled,
        "isPushTokenRegistered" to status.isPushTokenRegistered
    )
}
