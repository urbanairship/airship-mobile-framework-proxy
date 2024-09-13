
package com.urbanairship.android.framework.proxy

import com.urbanairship.json.JsonValue
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
public class NotificationStatusTest {

    @Test
    public fun testSimpleJson() {
        val json = """
            {
                "isUserNotificationsEnabled":true,
                "areNotificationsAllowed":false,
                "isPushPrivacyFeatureEnabled":true,
                "isUserOptedIn":true,
                "isOptedIn":false,
                "isPushTokenRegistered":false
            }
        """

        val parsed = NotificationStatus(JsonValue.parseString(json))

        val expected = NotificationStatus(
            isUserNotificationsEnabled = true,
            areNotificationsAllowed = false,
            isPushPrivacyFeatureEnabled = true,
            isPushTokenRegistered = false,
            isUserOptedIn = true,
            isOptedIn = false,
            notificationPermissionStatus = null
        )

        assertEquals(expected, parsed)
        assertEquals(parsed.toJsonValue(), JsonValue.parseString(json))
    }
}
