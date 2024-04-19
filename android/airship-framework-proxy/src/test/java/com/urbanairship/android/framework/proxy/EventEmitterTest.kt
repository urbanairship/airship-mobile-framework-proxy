package com.urbanairship.android.framework.proxy

import com.urbanairship.android.framework.proxy.events.EventEmitter
import com.urbanairship.json.JsonMap
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
public class EventEmitterTest {

    private val emitter = EventEmitter()

    @Test
    public fun testProcessPendingOrder() {
        emitter.addEvent(TestEvent(EventType.BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED))
        emitter.addEvent(TestEvent(EventType.FOREGROUND_NOTIFICATION_RESPONSE_RECEIVED))
        emitter.addEvent(TestEvent(EventType.BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED))

        assert(emitter.hasEvents(EventType.values().toList()))

        var order = mutableListOf<EventType>()
        emitter.processPending(EventType.values().toList()) {
            order.add(it.type)
        }

        assert(
            order == listOf(
                EventType.BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED,
                EventType.FOREGROUND_NOTIFICATION_RESPONSE_RECEIVED,
                EventType.BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED
            )
        )

        assert(!emitter.hasEvents(EventType.values().toList()))
    }
}

public class TestEvent(override val type: EventType, override val body: JsonMap = JsonMap.EMPTY_MAP): Event
