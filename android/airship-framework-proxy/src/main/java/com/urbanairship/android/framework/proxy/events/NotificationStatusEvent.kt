/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.NotificationStatus
import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf

/**
 * Notification status event.
 *
 * @param status The status.
 */
internal class NotificationStatusEvent(private val status: NotificationStatus) : Event {
    override val type = EventType.NOTIFICATION_STATUS_CHANGED
    override val body: JsonMap = jsonMapOf(
        "status" to status
    )
}
