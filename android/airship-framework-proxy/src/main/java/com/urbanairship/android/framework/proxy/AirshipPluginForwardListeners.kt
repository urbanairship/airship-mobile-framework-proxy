/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import com.urbanairship.actions.DeepLinkListener
import com.urbanairship.push.NotificationListener

/**
 * Optional forward listeners for the plugin.
 */
@Deprecated("Use AirshipPluginExtensions instead.")
public object AirshipPluginForwardListeners {
    /**
     * Deep link listener
     */
    public var deepLinkListener: DeepLinkListener? = null

    /**
     * Notification Listener
     */
    public var notificationListener: NotificationListener? = null
}
