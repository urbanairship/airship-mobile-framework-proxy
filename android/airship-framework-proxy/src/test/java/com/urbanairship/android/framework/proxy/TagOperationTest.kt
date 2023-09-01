package com.urbanairship.android.framework.proxy

import com.urbanairship.channel.TagEditor
import com.urbanairship.json.JsonException
import com.urbanairship.json.JsonValue
import io.mockk.confirmVerified
import io.mockk.mockk
import io.mockk.verify
import org.junit.Assert
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
public class TagOperationTest {

    @Test
    public fun testParseAdd() {
        val json = """
            {
                "tags": ["oneTag", "anotherTag", "andALastOne"],
                "operationType": "add"
            }
        """

        val parsed = TagOperation(json = JsonValue.parseString(json).requireMap())

        val expected = TagOperation(
            tags = listOf("oneTag", "anotherTag", "andALastOne"),
            action = TagOperationAction.ADD
        )

        Assert.assertEquals(expected, parsed)
    }

    @Test
    public fun testParseRemove() {
        val json = """
            {
                "tags": ["oneTag", "anotherTag", "andALastOne"],
                "operationType": "remove"
            }
        """

        val parsed = TagOperation(json = JsonValue.parseString(json).requireMap())

        val expected = TagOperation(
            tags = listOf("oneTag", "anotherTag", "andALastOne"),
            action = TagOperationAction.REMOVE
        )

        Assert.assertEquals(expected, parsed)
    }

    @Test(expected = IllegalArgumentException::class)
    public fun testParseInvalidAction() {
        val json = """
            {
                "tags": ["oneTag", "anotherTag", "andALastOne"],
                "operationType": "invalidAction"
            }
        """

        TagOperation(json = JsonValue.parseString(json).requireMap())
    }

    @Test(expected = JsonException::class)
    public fun testParseInvalidTags() {
        val json = """
            {
                "tags": "invalidTag",
                "operationType": "add"
            }
        """

        TagOperation(json = JsonValue.parseString(json).requireMap())
    }

    @Test
    public fun testApplyAdd() {
        val editor = mockk<TagEditor>(relaxed = true)

        val tags = listOf("oneTag", "anotherTag", "andALastOne")

        val operation = TagOperation(
            tags = tags,
            action = TagOperationAction.ADD
        )

        operation.applyOperation(editor)
        verify { editor.addTags(tags.toSet()) }
        confirmVerified(editor)
    }

    @Test
    public fun testApplyRemove() {
        val editor = mockk<TagEditor>(relaxed = true)

        val tags = listOf("oneTag", "anotherTag", "andALastOne")

        val operation = TagOperation(
            tags = tags,
            action = TagOperationAction.REMOVE
        )

        operation.applyOperation(editor)
        verify { editor.removeTags(tags.toSet()) }
        confirmVerified(editor)
    }

}
