
package com.urbanairship.android.framework.proxy

import com.urbanairship.contacts.Scope
import com.urbanairship.json.JsonValue
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.*

@RunWith(RobolectricTestRunner::class)
public class ScopedSubscriptionListOperationTest {

    @Test
    public fun testParse() {
        val json = """
            {
                "listId": "some list",
                "action": "subscribe",
                "scope": "app"
            }
        """

        val parsed = ScopedSubscriptionListOperation(json = JsonValue.parseString(json).requireMap())

        val expected = ScopedSubscriptionListOperation(
            action = SubscriptionListOperationAction.SUBSCRIBE,
            scope = Scope.APP,
            listId = "some list"
        )

        assertEquals(expected, parsed)
    }

    @Test(expected = IllegalArgumentException::class)
    public fun testParseInvalidScope() {
        val json = """
           {
               "listId": "some list",
               "action": "subscribe",
               "scope": "invalid"
           }
        """

        ScopedSubscriptionListOperation(json = JsonValue.parseString(json).requireMap())
    }
}
