package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType

internal class PushTokenReceivedEvent(pushToken: String) : Event {
    override val type: EventType = EventType.PUSH_TOKEN_RECEIVED
    override val body: Map<String, Any> = mapOf("pushToken" to pushToken)
}
