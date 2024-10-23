/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.UAirship

/**
 * Extender that will be called during takeOff to customize the airship instance.
 * Register the extender fully qualified class name in the manifest under the key
 * `com.urbanairship.plugin.extender`.
 */
public interface AirshipPluginExtender {

    /**
     * Used to customize Airship before takeOff is complete. Avoid long running, blocking
     * calls in this callback as it will delay Airship from being able to process notifications.
     * @param context The application context.
     * @param airship The airship instance.
     */
    public fun onAirshipReady(context: Context, airship: UAirship)

    /**
     * Used to extend the AirshipConfig. The configBuilder will have the default config applied from the properties file if available,
     * any config defined by the module.
     * @param context The application context.
     * @param configBuilder The config builder
     * @return The config builder.
     */
    public fun extendConfig(
        context: Context,
        configBuilder: AirshipConfigOptions.Builder
    ): AirshipConfigOptions.Builder {
        return configBuilder
    }
}

