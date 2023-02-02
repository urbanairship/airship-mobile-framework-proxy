/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.android.framework.proxy.Utils
import com.urbanairship.push.NotificationInfo
import com.urbanairship.push.PushMessage

/**
 * Push received event.
 */
internal class PushReceivedEvent : Event {

    override val body: Map<String, Any>
    override val type = EventType.PUSH_RECEIVED

    /**
     * Default constructor.
     *
     * @param message The push message.
     */
    constructor(message: PushMessage) {
        this.body = mapOf(
            "pushPayload" to Utils.notificationMap(message)
        )
    }

    /**
     * Default constructor.
     *
     * @param notificationInfo The posted notification info.
     */
    constructor(notificationInfo: NotificationInfo) {
        this.body = mapOf(
            "pushPayload" to Utils.notificationMap(
                notificationInfo.message,
                notificationInfo.notificationId,
                notificationInfo.notificationTag
            )
        )
    }

}
