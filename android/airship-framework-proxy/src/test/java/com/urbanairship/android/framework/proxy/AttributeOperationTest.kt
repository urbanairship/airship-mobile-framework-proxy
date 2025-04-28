
package com.urbanairship.android.framework.proxy

import com.urbanairship.channel.AttributeEditor
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf
import io.mockk.confirmVerified
import io.mockk.mockk
import io.mockk.verify
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.*

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
    public fun testRemoveJson() {
        val json = """
            {
                "key": "some attribute",
                "action": "remove",
                "instance_id": "Some instance"
            }
        """

        val parsed = AttributeOperation(json = JsonValue.parseString(json).requireMap())

        val expected = AttributeOperation(
            attribute = "some attribute",
            value = null,
            action = AttributeOperationAction.REMOVE,
            valueType = null,
            instanceId = "Some instance"
        )

        assertEquals(expected, parsed)
    }

    @Test
    public fun testJson() {
        val json = """
            {
                "key": "some attribute",
                "action": "set",
                "value": { "foo": "bar" },
                "type": "json",
                "instance_id": "instance"
            }
        """

        val parsed = AttributeOperation(json = JsonValue.parseString(json).requireMap())

        val expected = AttributeOperation(
            attribute = "some attribute",
            value = jsonMapOf("foo" to "bar").toJsonValue(),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.JSON,
            instanceId = "instance"
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

    @Test
    public fun testApplyJson() {
        val editor = mockk<AttributeEditor>(relaxed = true)

        val operation  = AttributeOperation(
            attribute = "some attribute",
            value = jsonMapOf("foo" to "bar").toJsonValue(),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.JSON,
            instanceId = "instance id",
            expiry = Date(1000)
        )

        operation.applyOperation(editor)

        verify { editor.setAttribute(
            attribute = "some attribute",
            instanceId = "instance id",
            expiration = Date(1000),
            json = jsonMapOf("foo" to "bar")
        ) }
        confirmVerified(editor)
    }

    @Test
    public fun testApplyString() {
        val editor = mockk<AttributeEditor>(relaxed = true)

        val operation  = AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.wrapOpt("neat"),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.STRING
        )

        operation.applyOperation(editor)

        verify { editor.setAttribute("some attribute", "neat") }
        confirmVerified(editor)
    }

    @Test
    public fun testApplyNumber() {
        val editor = mockk<AttributeEditor>(relaxed = true)

        val operation  = AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.wrapOpt(100.1),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.NUMBER
        )

        operation.applyOperation(editor)

        verify { editor.setAttribute("some attribute", 100.1) }
        confirmVerified(editor)
    }

    @Test
    public fun testApplyDate() {
        val editor = mockk<AttributeEditor>(relaxed = true)

        val operation  = AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.wrapOpt(1682681877000),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.DATE
        )

        operation.applyOperation(editor)

        verify { editor.setAttribute("some attribute", Date(1682681877000)) }
        confirmVerified(editor)
    }

    @Test
    public fun testApplyRemove() {
        val editor = mockk<AttributeEditor>(relaxed = true)

        val operation = AttributeOperation(
            attribute = "some attribute",
            value = null,
            action = AttributeOperationAction.REMOVE,
            valueType = null
        )

        operation.applyOperation(editor)

        verify { editor.removeAttribute("some attribute") }
        confirmVerified(editor)
    }

    @Test
    public fun testApplyRemoveJson() {
        val editor = mockk<AttributeEditor>(relaxed = true)

        val operation = AttributeOperation(
            attribute = "some attribute",
            value = null,
            action = AttributeOperationAction.REMOVE,
            valueType = null,
            instanceId = "some instance"
        )

        operation.applyOperation(editor)

        verify { editor.removeAttribute("some attribute", "some instance") }
        confirmVerified(editor)
    }

    @Test(expected = java.lang.Exception::class)
    public fun testApplyInvalidString() {
        val editor = mockk<AttributeEditor>()

        AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.wrapOpt(1682681877000),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.STRING
        ).applyOperation(editor)
    }


    @Test(expected = java.lang.Exception::class)
    public fun testApplyNullString() {
        val editor = mockk<AttributeEditor>()

        AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.NULL,
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.STRING
        ).applyOperation(editor)
    }

    @Test(expected = java.lang.Exception::class)
    public fun testApplyInvalidNumber() {
        val editor = mockk<AttributeEditor>()

        AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.wrapOpt("nope"),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.NUMBER
        ).applyOperation(editor)
    }


    @Test(expected = java.lang.Exception::class)
    public fun testApplyNullNumber() {
        val editor = mockk<AttributeEditor>()

        AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.NULL,
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.NUMBER
        ).applyOperation(editor)
    }

    @Test(expected = java.lang.Exception::class)
    public fun testApplyInvalidDate() {
        val editor = mockk<AttributeEditor>()

        AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.wrapOpt("nope"),
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.DATE
        ).applyOperation(editor)
    }


    @Test(expected = java.lang.Exception::class)
    public fun testApplyNullDate() {
        val editor = mockk<AttributeEditor>()

        AttributeOperation(
            attribute = "some attribute",
            value = JsonValue.NULL,
            action = AttributeOperationAction.SET,
            valueType = AttributeValueType.DATE
        ).applyOperation(editor)
    }
}
