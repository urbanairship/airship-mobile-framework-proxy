/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.android.framework.proxy.Utils
import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf
import com.urbanairship.push.NotificationInfo
import com.urbanairship.push.PushMessage

/**
 * Push received event.
 */
internal class PushReceivedEvent : Event {

    override val body: JsonMap
    override val type: EventType

    constructor(body: JsonMap, isForeground: Boolean) {
        this.body = body

        this.type = if (isForeground) {
            EventType.FOREGROUND_PUSH_RECEIVED
        } else {
            EventType.BACKGROUND_PUSH_RECEIVED
        }
    }

    /**
     * Default constructor.
     *
     * @param message The push message.
     * @param isForeground If received in the foreground or not.
     */
    constructor(message: PushMessage, isForeground: Boolean) : this(
        jsonMapOf(
            "pushPayload" to Utils.notificationMap(message),
            "isForeground" to isForeground
        ),
        isForeground
    )

    /**
     * Default constructor.
     *
     * @param notificationInfo The posted notification info.
     * @param isForeground If received in the foreground or not.
     */
    constructor(notificationInfo: NotificationInfo, isForeground: Boolean) : this(
        jsonMapOf(
            "pushPayload" to Utils.notificationMap(
                notificationInfo.message,
                notificationInfo.notificationId,
                notificationInfo.notificationTag
            ),
            "isForeground" to isForeground
        ),
        isForeground
    )

}
