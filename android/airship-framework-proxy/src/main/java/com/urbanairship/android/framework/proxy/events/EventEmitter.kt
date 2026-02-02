/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.UALog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch

/**
 * Emits events to listeners in the JS layer.
 */
public class EventEmitter {
    private val lock = Any()

    private val scope: CoroutineScope = CoroutineScope(Dispatchers.IO)

    private val pendingEvents = mutableListOf<Event>()
    private val _pendingEventsUpdates = MutableSharedFlow<Event>()
    public val pendingEventListener: SharedFlow<Event> = _pendingEventsUpdates

    /**
     * Adds an event.
     *
     * @param event The event.
     */
    public fun addEvent(event: Event, replacePending: Boolean = false) {
        synchronized(lock) {
            if (replacePending) {
                val removed = pendingEvents.removeAll { event.type == it.type }
                UALog.v { "addEvent replacePending=true, type=${event.type}, removed=$removed, pendingCount=${pendingEvents.size}" }
            }
            pendingEvents.add(event)
            UALog.v { "addEvent emitted event: type=${event.type}, body=${event.body}, replacePending=$replacePending" }
            scope.launch {
                _pendingEventsUpdates.emit(event)
            }
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
            pendingEvents.removeAll {
                types.contains(it.type) && result.add(it)
            }
            UALog.v { "takePending types=$types, taken=${result.size}, remainingPending=${pendingEvents.size}" }
            return result
        }
    }

    public fun hasEvents(types: List<EventType>): Boolean {
        synchronized(lock) {
            val has = pendingEvents.firstOrNull { types.contains(it.type) } != null
            UALog.v { "hasEvents types=$types, hasMatching=$has, pendingCount=${pendingEvents.size}" }
            return has
        }
    }

    /**
     * Processes events for the given types.
     * @param types The types.
     * @param onProcess The process callback. Return true to remove the event as pending.
     */
    public fun processPending(types: List<EventType>, onProcess: (Event) -> Boolean) {
        synchronized(lock) {
            val before = pendingEvents.size
            val removed = pendingEvents.removeAll {
                if (!types.contains(it.type)) {
                    false
                } else {
                    onProcess(it)
                }
            }
            UALog.v { "processPending types=$types, processed=$removed, pendingBefore=$before, pendingAfter=${pendingEvents.size}" }
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
