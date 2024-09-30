/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import com.urbanairship.UAirship

/**
 * Extender that will be called during takeOff to customize the airship instance.
 * Register the extender fully qualified class name in the manifest under the key
 * `com.urbanairship.plugin.AIRSHIP_EXTENDER`.
 */
public interface AirshipPluginExtender {
    public fun onAirshipReady(context: Context, airship: UAirship)
}
