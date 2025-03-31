/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import com.urbanairship.push.NotificationListener
import com.urbanairship.push.PushMessage

/**
 * A class that manages hooks for extending and overriding functionality in plugin-based frameworks.
 *
 * The `AirshipPluginExtensions` object provides hooks (closures and listeners) that allow hybrid apps or plugin developers
 * to customize or override default behavior in the underlying native Airship SDK. These hooks enable apps built with frameworks
 * like React Native, Cordova, Capacitor, and Flutter to modify certain behaviors without breaking the base plugin.
 *
 * These extension points provide flexibility for app developers to extend Airship's behavior based on specific needs, such as
 * handling deep links, customizing foreground notification behavior, and forwarding notifications to other handlers.
 */
public object AirshipPluginExtensions {

    /**
     * A function that allows overriding the behavior when a deep link is triggered.
     *
     * This function is invoked when a deep link is detected. It should return an
     * `AirshipPluginOverride<Unit>`, which will determine whether the default deep link behavior
     * should be used (`UseDefault`) or if the behavior should be overridden (`Override()`).
     *
     * @return An `AirshipPluginOverride<Unit>` that determines whether to override the default deep link handling.
     */
    public var onDeepLink: ((deepLink: String) -> AirshipPluginOverride<Unit>)? = null

    /**
     * A suspend function that allows overriding the decision of whether to display a foreground notification.
     *
     * This function is invoked when a push notification is about to be displayed in the foreground. It should return an
     * `AirshipPluginOverride<Boolean>`, which will determine whether the default display behavior
     * should be used (`UseDefault`) or if the behavior should be overridden (`Override(true/false)`).
     *
     * @return An `AirshipPluginOverride<Boolean>` indicating whether to override the default foreground display of a notification.
     */
    public var onShouldDisplayForegroundNotification: (suspend (PushMessage) -> AirshipPluginOverride<Boolean>)? = null

    /**
     * A listener for forwarding notifications.
     *
     * This listener is invoked when a notification needs to be forwarded to another handler, such as a custom
     * notification handler. It allows the app to intercept notifications and forward them to another listener.
     */
    public var forwardNotificationListener: NotificationListener? = null
}

/**
 * Represents the result of an override operation.
 *
 * `AirshipPluginOverride` is a sealed class that can either use the default behavior
 * or override it with a custom result. It is used across various parts of the plugin system
 * to allow plugins to customize or override certain actions.
 */
public sealed class AirshipPluginOverride<out T> {

    /**
     * Represents the default behavior for an override.
     *
     * This object is used when the default behavior should be used, as opposed to
     * overriding it with custom logic. For example, if a plugin doesn't want to
     * override a specific behavior, it would return this object.
     */
    public data object UseDefault : AirshipPluginOverride<Nothing>()

    /**
     * Represents an overridden result.
     *
     * This class holds a result that overrides the default behavior. The result
     * can be of any type (`T`) and is used when a custom action or value is
     * needed to replace the default behavior.
     *
     * @param result The value that overrides the default behavior.
     */
    public data class Override<T>(val result: T) : AirshipPluginOverride<T>()

    public companion object {
        @JvmStatic
        public fun Override(): Override<Unit> = Override(Unit)
    }
}
