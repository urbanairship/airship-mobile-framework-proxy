package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.android.framework.proxy.PendingEmbedded
import com.urbanairship.UALog
import com.urbanairship.android.framework.proxy.events.EventEmitter
import com.urbanairship.android.framework.proxy.events.PendingEmbeddedUpdated
import com.urbanairship.automation.InAppAutomation

public class InAppProxy internal constructor(private val inAppProvider: () -> InAppAutomation) {

    public fun setPaused(paused: Boolean) {
        UALog.v { "setPaused called, paused=$paused" }
        inAppProvider().isPaused = paused
    }

    public fun isPaused(): Boolean {
        UALog.v { "isPaused called" }
        return inAppProvider().isPaused
    }

    public fun setDisplayInterval(milliseconds: Long) {
        UALog.v { "setDisplayInterval called, milliseconds=$milliseconds" }
        inAppProvider().inAppMessaging.displayInterval = milliseconds
    }

    public fun getDisplayInterval(): Long {
        UALog.v { "getDisplayInterval called" }
        return inAppProvider().inAppMessaging.displayInterval
    }

    public fun resendLastEmbeddedEvent() {
        UALog.v { "resendLastEmbeddedEvent called" }
        PendingEmbedded.pending.value.let {
            EventEmitter.shared().addEvent(PendingEmbeddedUpdated(it), replacePending = true)
        }
    }
}
