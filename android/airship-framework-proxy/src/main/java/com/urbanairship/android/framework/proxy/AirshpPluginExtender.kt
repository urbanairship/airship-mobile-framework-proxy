/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Context
import com.urbanairship.AirshipConfigOptions
import com.urbanairship.UAirship

/**
 * Extender that will be called during `takeOff` to customize the Airship instance.
 *
 * The `AirshipPluginExtender` interface allows you to customize the initialization of the Airship SDK
 * during the app's startup process. By implementing this interface and registering it in the Android
 * manifest, you can extend Airship's behavior before the `takeOff` method is completed.
 *
 * To register your extender, include the following in your app's `AndroidManifest.xml`:
 *
 * ```xml
 * <application ...>
 *
 *     <meta-data android:name="com.urbanairship.plugin.extender"
 *         android:value="com.example.AirshipExtender" />
 *
 *     <!-- ... -->
 * </application>
 * ```
 *
 * The `AirshipPluginExtender` provides two methods:
 * - `onAirshipReady`: Called when the Airship SDK is initialized and ready to be used. It allows you to
 *   perform custom logic after the SDK is ready.
 * - `extendConfig`: Used to modify the Airship SDK configuration before the SDK takes off.
 */
public interface AirshipPluginExtender {

    /**
     * Used to customize Airship before takeOff is complete.
     *
     * This method is called during the initialization process, before the Airship SDK has fully taken off.
     * It is the ideal place to set extensions or customizations, ensuring they are applied before they are used
     * by the Airship SDK. This includes configuring listeners, overrides, or custom behaviors.
     *
     * **Important:** Avoid long-running or blocking calls in this callback as it will delay Airship from being able
     * to process notifications.
     *
     * @param context The application context.
     */
    public fun onAirshipReady(context: Context)

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

