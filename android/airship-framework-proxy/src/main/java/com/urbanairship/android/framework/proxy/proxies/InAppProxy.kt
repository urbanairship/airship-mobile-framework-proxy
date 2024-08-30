package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.android.framework.proxy.PendingEmbedded
import com.urbanairship.android.framework.proxy.events.EventEmitter
import com.urbanairship.android.framework.proxy.events.PendingEmbeddedUpdated
import com.urbanairship.automation.InAppAutomation
import java.util.concurrent.TimeUnit

public class InAppProxy internal constructor(private val inAppProvider: () -> InAppAutomation) {

    public fun setPaused(paused: Boolean) {
        inAppProvider().isPaused = paused
    }

    public fun isPaused(): Boolean {
        return inAppProvider().isPaused
    }

    public fun setDisplayInterval(milliseconds: Long) {
        inAppProvider().inAppMessaging.displayInterval = milliseconds
    }

    public fun getDisplayInterval(): Long {
        return inAppProvider().inAppMessaging.displayInterval
    }

    public fun resendLastEmbeddedEvent() {
        PendingEmbedded.pending.value.let {
            EventEmitter.shared().addEvent(PendingEmbeddedUpdated(it), replacePending = true)
        }
    }
}
