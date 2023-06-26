/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy.events

import com.urbanairship.android.framework.proxy.Event
import com.urbanairship.android.framework.proxy.EventType
import com.urbanairship.json.JsonMap
import com.urbanairship.json.jsonMapOf

/**
 * Deep link event.
 */
internal class DeepLinkEvent(deepLink: String) : Event {

    override val type = EventType.DEEP_LINK_RECEIVED

    override val body: JsonMap = jsonMapOf("deepLink" to deepLink)

}
