/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType

/**
 * Registration event.
 *
 * @param channelId The channel ID.
 */
internal class ChannelCreatedEvent(channelId: String) : Event {

    override val type = EventType.CHANNEL_CREATED

    override val body: Map<String, Any> = mapOf("channelId" to channelId)
}
