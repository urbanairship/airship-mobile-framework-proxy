/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import com.urbanairship.UALog

/**
 * Plugin logger.
 *
 * @deprecated Use [UALog] instead. This class is retained for backward compatibility only.
 */
@Deprecated("Use UALog instead", ReplaceWith("UALog"))
public object ProxyLogger {

    /**
     * Send a warning log message.
     *
     * @param message The message you would like logged.
     * @param args The message args.
     */
    @Deprecated("Use UALog.w instead", ReplaceWith("UALog.w(message, *args)"))
    @JvmStatic
    public fun warn(message: String, vararg args: Any?) {
        UALog.w(message, *args)
    }

    /**
     * Send a warning log message.
     *
     * @param t An exception to log
     * @param message The message you would like logged.
     * @param args The message args.
     */
    @Deprecated("Use UALog.w instead", ReplaceWith("UALog.w(t, message, *args)"))
    @JvmStatic
    public fun warn(t: Throwable, message: String, vararg args: Any?) {
        UALog.w(t, message, *args)
    }

    /**
     * Send a warning log message.
     *
     * @param t An exception to log
     */
    @Deprecated("Use UALog.w instead", ReplaceWith("UALog.w(t)"))
    @JvmStatic
    public fun warn(t: Throwable) {
        UALog.w(t)
    }

    /**
     * Send a verbose log message.
     *
     * @param message The message you would like logged.
     * @param args The message args.
     */
    @Deprecated("Use UALog.v instead", ReplaceWith("UALog.v(message, *args)"))
    @JvmStatic
    public fun verbose(message: String, vararg args: Any?) {
        UALog.v(message, *args)
    }

    /**
     * Send a debug log message.
     *
     * @param message The message you would like logged.
     * @param args The message args.
     */
    @Deprecated("Use UALog.d instead", ReplaceWith("UALog.d(message, *args)"))
    @JvmStatic
    public fun debug(message: String, vararg args: Any?) {
        UALog.d(message, *args)
    }

    /**
     * Send a debug log message.
     *
     * @param t An exception to log
     * @param message The message you would like logged.
     * @param args The message args.
     */
    @Deprecated("Use UALog.d instead", ReplaceWith("UALog.d(t, message, *args)"))
    @JvmStatic
    public fun debug(t: Throwable, message: String, vararg args: Any?) {
        UALog.d(t, message, *args)
    }

    /**
     * Send an info log message.
     *
     * @param message The message you would like logged.
     * @param args The message args.
     */
    @Deprecated("Use UALog.i instead", ReplaceWith("UALog.i(message, *args)"))
    @JvmStatic
    public fun info(message: String, vararg args: Any) {
        UALog.i(message, *args)
    }

    /**
     * Send an info log message.
     *
     * @param t An exception to log
     * @param message The message you would like logged.
     * @param args The message args.
     */
    @Deprecated("Use UALog.i instead", ReplaceWith("UALog.i(t, message, *args)"))
    @JvmStatic
    public fun info(t: Throwable, message: String, vararg args: Any?) {
        UALog.i(t, message, *args)
    }

    /**
     * Send an error log message.
     *
     * @param message The message you would like logged.
     * @param args The message args.
     */
    @Deprecated("Use UALog.e instead", ReplaceWith("UALog.e(message, *args)"))
    @JvmStatic
    public fun error(message: String, vararg args: Any?) {
        UALog.e(message, *args)
    }

    /**
     * Send an error log message.
     *
     * @param t An exception to log
     */
    @Deprecated("Use UALog.e instead", ReplaceWith("UALog.e(t)"))
    @JvmStatic
    public fun error(t: Throwable) {
        UALog.e(t)
    }

    /**
     * Send an error log message.
     *
     * @param t An exception to log
     * @param message The message you would like logged.
     * @param args The message args.
     */
    @Deprecated("Use UALog.e instead", ReplaceWith("UALog.e(t, message, *args)"))
    @JvmStatic
    public fun error(t: Throwable, message: String, vararg args: Any?) {
        UALog.e(t, message, *args)
    }
}
