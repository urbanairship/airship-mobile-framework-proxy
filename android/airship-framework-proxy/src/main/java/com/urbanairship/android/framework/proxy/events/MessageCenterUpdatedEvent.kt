/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf

/**
 * Inbox updated event.
 *
 * @param unreadCount The number of unread messages in the message center.
 * @param count The number of total messages in the message center.
 */
internal class MessageCenterUpdatedEvent(unreadCount: Int, count: Int) : Event {
    override val type = EventType.MESSAGE_CENTER_UPDATED

    override val body: JsonMap = jsonMapOf(
        "messageUnreadCount" to unreadCount,
        "messageCount" to count
    )
}
