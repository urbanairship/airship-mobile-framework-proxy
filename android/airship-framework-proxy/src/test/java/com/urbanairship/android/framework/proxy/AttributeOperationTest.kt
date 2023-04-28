
package com.urbanairship.android.framework.proxy

import com.urbanairship.json.JsonValue
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
public class AttributeOperationTest {

    @Test
    public fun testRemove() {
        val json = """
            {
                "key": "some attribute",
                "action": "remove"
            }
        """

        val parsed = AttributeOperation(json = JsonValue.parseString(json).requireMap())

        val expected = AttributeOperation(
            attribute = "some attribute",
            value = null,
            action = AttributeOperationAction.REMOVE,
            valueType = null
        )

        assertEquals(expected, parsed)
    }
    @Test
    public fun testDate() {
        val json = """
            {
                "key": "some attribute",
                "action": "set",
                "value": 1682681877000,
                "type": "date"
            }
        """

        val parsed = AttributeOperation(json = JsonValue.parseString(json).requireMap())

        val expected = AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.wrapOpt(1682681877000),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.DATE
        )

        assertEquals(expected, parsed)
    }

    @Test
    public fun testString() {
        val json = """
            {
                "key": "some attribute",
                "action": "set",
                "value": "neat",
                "type": "string"
            }
        """

        val parsed = AttributeOperation(json = JsonValue.parseString(json).requireMap())

        val expected = AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.wrapOpt("neat"),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.STRING
        )

        assertEquals(expected, parsed)
    }

    @Test
    public fun testNumber() {
        val json = """
            {
                "key": "some attribute",
                "action": "set",
                "value": 10.4,
                "type": "number"
            }
        """

        val parsed = AttributeOperation(json = JsonValue.parseString(json).requireMap())

        val expected = AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.wrapOpt(10.4),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.NUMBER
        )

        assertEquals(expected, parsed)
    }
}
