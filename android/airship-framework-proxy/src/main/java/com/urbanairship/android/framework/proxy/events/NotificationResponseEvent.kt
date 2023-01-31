/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.push.NotificationActionButtonInfo
import com.urbanairship.push.NotificationInfo
import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.android.framework.proxy.Utils

/**
 * Notification response event.
 *
 * @param notificationInfo The notification info.
 * @param actionButtonInfo The notification action button info.
 */
internal class NotificationResponseEvent(
    notificationInfo: NotificationInfo,
    actionButtonInfo: NotificationActionButtonInfo?
) : Event {

    override val type: EventType = if (actionButtonInfo?.isForeground == false) {
        EventType.BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED
    } else {
        EventType.FOREGROUND_NOTIFICATION_RESPONSE_RECEIVED
    }

    override val body: Map<String, Any> = run {
        val map = mutableMapOf(
            "pushPayload" to Utils.notificationMap(
                notificationInfo.message,
                notificationInfo.notificationId,
                notificationInfo.notificationTag
            ),
            "isForeground" to (type == EventType.FOREGROUND_NOTIFICATION_RESPONSE_RECEIVED),
        )
        actionButtonInfo?.buttonId?.let {
            map["actionId"] = it
        }
        map
    }
}

