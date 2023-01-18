/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.json.JsonMap

/**
 * Deep link event.
 */
internal class DeepLinkEvent(deepLink: String) : Event {

    override val type = EventType.DEEP_LINK_RECEIVED

    override val body: Map<String, Any> = mapOf("deepLink" to deepLink)

}