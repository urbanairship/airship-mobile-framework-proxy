package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf

internal class PushTokenReceivedEvent(pushToken: String) : Event {
    override val type: EventType = EventType.PUSH_TOKEN_RECEIVED
    override val body: JsonMap = jsonMapOf("pushToken" to pushToken)
}
