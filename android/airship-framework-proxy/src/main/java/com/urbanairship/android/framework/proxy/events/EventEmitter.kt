/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow

/**
 * Emits events to listeners in the JS layer.
 */
public class EventEmitter {
    private val lock = Any()

    private val pendingEvents = mutableMapOf<EventType, MutableList<Event>>()
    private val _pendingEventsUpdates = MutableSharedFlow<EventType>()
    public val pendingEventListener: SharedFlow<EventType> = _pendingEventsUpdates

    /**
     * Adds an event.
     *
     * @param event The event.
     */
    public fun addEvent(event: Event) {
        synchronized(lock) {
            pendingEvents.putIfAbsent(event.type, mutableListOf())
            pendingEvents[event.type]?.add(event)
        }
    }

    /**
     * Removes and returns events for the given types.
     * @param types The types to take.
     * @return A list of events.
     */
    public fun takePending(types: List<EventType>): List<Event> {
        synchronized(lock) {
            val result = mutableListOf<Event>()
            types.forEach { type ->
                result.addAll(pendingEvents.remove(type) ?: emptyList())
            }
            return result
        }
    }

    /**
     * Processes events for the given types.
     * @param types The types.
     * @param onProcess The process callback. Return true to remove the event as pending.
     */
    public fun processPending(types: List<EventType>, onProcess: (Event) -> Boolean) {
        synchronized(lock) {
            types.forEach { type ->
                pendingEvents[type]?.removeAll(onProcess)
            }
        }
    }

    public companion object {
        private val sharedInstance = EventEmitter()

        /**
         * Returns the shared {@link EventEmitter} instance.
         *
         * @return The shared {@link EventEmitter} instance.
         */
        @JvmStatic
        public fun shared(): EventEmitter {
            return sharedInstance
        }
    }
}