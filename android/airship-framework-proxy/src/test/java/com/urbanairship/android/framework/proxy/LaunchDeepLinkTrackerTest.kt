/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import androidx.core.os.bundleOf
import com.urbanairship.push.PushMessage
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.yield
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
public class LaunchDeepLinkTrackerTest {

    private fun message(deepLink: String? = null, key: String = "^d"): PushMessage {
        val extras = if (deepLink != null) {
            bundleOf(PushMessage.EXTRA_ACTIONS to """{"$key":"$deepLink"}""")
        } else {
            bundleOf()
        }
        return PushMessage(extras)
    }

    @Test
    public fun testTapWithDeepLinkStashes(): Unit = runTest {
        val tracker = LaunchDeepLinkTracker()
        tracker.onNotificationOpened(message("myapp://home"), isAppForegrounded = false)
        assertEquals("myapp://home", tracker.takeLaunchDeepLink())
    }

    @Test
    public fun testConsumeOnce(): Unit = runTest {
        val tracker = LaunchDeepLinkTracker()
        tracker.onNotificationOpened(message("myapp://home"), isAppForegrounded = false)
        tracker.takeLaunchDeepLink()
        assertNull(tracker.takeLaunchDeepLink())
    }

    @Test
    public fun testLongActionNameKey(): Unit = runTest {
        val tracker = LaunchDeepLinkTracker()
        tracker.onNotificationOpened(
            message("myapp://home", key = "deep_link_action"),
            isAppForegrounded = false
        )
        assertEquals("myapp://home", tracker.takeLaunchDeepLink())
    }

    @Test
    public fun testForegroundTapSkipsStash(): Unit = runTest {
        val tracker = LaunchDeepLinkTracker()
        tracker.onNotificationOpened(message("myapp://home"), isAppForegrounded = true)
        assertNull(tracker.takeLaunchDeepLink())
    }

    @Test
    public fun testTapWithoutDeepLinkResolvesNull(): Unit = runTest {
        val tracker = LaunchDeepLinkTracker()
        tracker.onNotificationOpened(message(), isAppForegrounded = false)
        assertNull(tracker.takeLaunchDeepLink())
    }

    @Test
    public fun testWaiterResolvedByLaterTap(): Unit = runTest {
        val tracker = LaunchDeepLinkTracker()
        val pending = async { tracker.takeLaunchDeepLink() }
        yield()
        tracker.onNotificationOpened(message("myapp://home"), isAppForegrounded = false)
        assertEquals("myapp://home", pending.await())
    }

    @Test
    public fun testWaiterResolvedNullOnLaunchResolved(): Unit = runTest {
        val tracker = LaunchDeepLinkTracker()
        val pending = async { tracker.takeLaunchDeepLink() }
        yield()
        tracker.markLaunchResolved()
        assertNull(pending.await())
    }

    @Test
    public fun testStaleStashReturnsNull(): Unit = runTest {
        var now = 0L
        val tracker = LaunchDeepLinkTracker(clock = { now })
        tracker.onNotificationOpened(message("myapp://home"), isAppForegrounded = false)
        now = 10_001L
        assertNull(tracker.takeLaunchDeepLink())
    }

    @Test
    public fun testFreshStashReturnsLink(): Unit = runTest {
        var now = 0L
        val tracker = LaunchDeepLinkTracker(clock = { now })
        tracker.onNotificationOpened(message("myapp://home"), isAppForegrounded = false)
        now = 9_999L
        assertEquals("myapp://home", tracker.takeLaunchDeepLink())
    }
}
