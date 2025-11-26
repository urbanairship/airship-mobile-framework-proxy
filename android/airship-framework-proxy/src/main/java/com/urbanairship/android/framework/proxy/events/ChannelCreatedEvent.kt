/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf

/**
 * Registration event.
 *
 * @param channelId The channel ID.
 */
internal class ChannelCreatedEvent(channelId: String) : Event {

    override val type = EventType.CHANNEL_CREATED

    override val body: JsonMap = jsonMapOf("channelId" to channelId)
}
