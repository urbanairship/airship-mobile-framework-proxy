package com.urbanairship.android.framework.proxy

import com.urbanairship.android.framework.proxy.events.Event
import com.urbanairship.android.framework.proxy.events.EventEmitter
import com.urbanairship.android.framework.proxy.events.EventType
import com.urbanairship.json.JsonMap
import junit.framework.TestCase.assertEquals
import junit.framework.TestCase.assertTrue
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

    @Test
    public fun testTakePendingFiltersByType() {
        emitter.addEvent(TestEvent(EventType.BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED))
        emitter.addEvent(TestEvent(EventType.BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED))
        emitter.addEvent(TestEvent(EventType.FOREGROUND_NOTIFICATION_RESPONSE_RECEIVED))
        emitter.addEvent(TestEvent(EventType.CHANNEL_CREATED))

        assertTrue(emitter.takePending(emptyList()).isEmpty())
        assertEquals(2, emitter.takePending(listOf(EventType.BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED)).size)
        assertEquals(0, emitter.takePending(listOf(EventType.BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED)).size)
        assertEquals(1, emitter.takePending(listOf(EventType.FOREGROUND_NOTIFICATION_RESPONSE_RECEIVED)).size)
        assertEquals(1, emitter.takePending(listOf(EventType.CHANNEL_CREATED)).size)
    }
}

public class TestEvent(override val type: EventType, override val body: JsonMap = JsonMap.EMPTY_MAP):
    Event
