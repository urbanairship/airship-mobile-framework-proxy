/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import com.urbanairship.push.PushMessage
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.getAndUpdate

/**
 * Tracks the deep link that launched the app from a notification tap.
 *
 * The stash is consume-once and expires after a short staleness window so a
 * JS reload can't replay an old launch link.
 */
public class LaunchDeepLinkTracker internal constructor(
    private val clock: () -> Long = { System.currentTimeMillis() }
) {

    private data class Stash(val deepLink: String, val timeMs: Long)

    private val stash = MutableStateFlow<Stash?>(null)
    private val launchResolved = MutableStateFlow(false)

    /**
     * Called when a notification is opened, before the SDK runs the
     * notification's actions. Resolves the launch, stashing the payload's
     * deep link when the app was not already foregrounded.
     */
    internal fun onNotificationOpened(message: PushMessage, isAppForegrounded: Boolean) {
        if (!isAppForegrounded) {
            DEEP_LINK_ACTION_KEYS.firstNotNullOfOrNull { message.actions[it]?.string }?.let {
                stash.value = Stash(it, clock())
            }
        }
        launchResolved.value = true
    }

    /**
     * Resolves the launch without a deep link. Called once the app is
     * foregrounded so normal launches resolve null without waiting.
     */
    internal fun markLaunchResolved() {
        launchResolved.value = true
    }

    /**
     * Returns the deep link that launched the app, or null. Consumes the value.
     */
    public suspend fun takeLaunchDeepLink(): String? {
        take()?.let { return it }
        launchResolved.first { it }
        return take()
    }

    private fun take(): String? {
        val current = stash.getAndUpdate { null } ?: return null
        return if (clock() - current.timeMs <= MAX_STASH_AGE_MS) current.deepLink else null
    }

    public companion object {
        private val DEEP_LINK_ACTION_KEYS = listOf("^d", "deep_link_action")
        private const val MAX_STASH_AGE_MS = 10_000L

        private val sharedInstance = LaunchDeepLinkTracker()

        /**
         * Shared tracker instance.
         */
        @JvmStatic
        public fun shared(): LaunchDeepLinkTracker = sharedInstance
    }
}
