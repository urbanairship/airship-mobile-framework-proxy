/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
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
    public fun addEvent(event: Event) {
        synchronized(lock) {
            pendingEvents.add(event)
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
                types.contains(it.type)
                result.add(it)
            }
            return result
        }
    }

    public fun hasEvents(types: List<EventType>): Boolean {
        synchronized(lock) {
            return pendingEvents.firstOrNull {
                types.contains(it.type)
            } != null
        }
    }

    /**
     * Processes events for the given types.
     * @param types The types.
     * @param onProcess The process callback. Return true to remove the event as pending.
     */
    public fun processPending(types: List<EventType>, onProcess: (Event) -> Boolean) {
        synchronized(lock) {
            pendingEvents.removeAll {
                if (!types.contains(it.type)) {
                    false
                } else {
                    onProcess(it)
                }
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
