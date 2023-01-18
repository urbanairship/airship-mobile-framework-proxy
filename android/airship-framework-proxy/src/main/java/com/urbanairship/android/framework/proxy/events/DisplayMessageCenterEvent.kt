/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.json.JsonMap

/**
 * Show inbox event.
 *
 * @param messageId The optional message ID.
 */
internal class DisplayMessageCenterEvent(messageId: String?) : Event {

    override val type = EventType.DISPLAY_MESSAGE_CENTER

    override val body: Map<String, Any> = messageId?.let { mapOf("messageId" to it) } ?: emptyMap()
}