/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType

/**
 * Notification opt-in status event.
 *
 * @param optInStatus The app opt-in status.
 */
internal class NotificationOptInEvent(private val optInStatus: Boolean) : Event {
    override val type = EventType.NOTIFICATION_OPT_IN_CHANGED
    override val body: Map<String, Any> = mapOf("optIn" to optInStatus)

}
