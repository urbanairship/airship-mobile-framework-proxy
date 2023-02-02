/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

public enum class EventType {
    CHANNEL_CREATED,
    DEEP_LINK_RECEIVED,
    DISPLAY_MESSAGE_CENTER,
    DISPLAY_PREFERENCE_CENTER,
    MESSAGE_CENTER_UPDATED,
    PUSH_TOKEN_RECEIVED,
    FOREGROUND_NOTIFICATION_RESPONSE_RECEIVED,
    BACKGROUND_NOTIFICATION_RESPONSE_RECEIVED,
    PUSH_RECEIVED,
    NOTIFICATION_OPT_IN_CHANGED
}

/**
 * Event interface.
 */
public interface Event {

    /**
     * The event name.
     */
    public val type: EventType

    /**
     * The event body.
     */
    public val body: Map<String, Any>
}
