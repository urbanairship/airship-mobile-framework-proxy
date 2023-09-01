package com.urbanairship.android.framework.proxy

import com.urbanairship.channel.TagEditor
import com.urbanairship.channel.TagGroupsEditor
import com.urbanairship.json.JsonMap

public enum class TagOperationAction {
    ADD, REMOVE
}

public data class TagOperation(
    public val tags: List<String>,
    public val action: TagOperationAction
) {
    public constructor(json: JsonMap) : this(
        tags = json.require("tags").requireList().map { it.requireString() },
        action = TagOperationAction.valueOf(
            json.require("operationType").requireString().uppercase()
        )
    )
}

internal fun TagOperation.applyOperation(editor: TagEditor) {
    when (this.action) {
        TagOperationAction.ADD -> editor.addTags(this.tags.toSet())
        TagOperationAction.REMOVE -> editor.removeTags(this.tags.toSet())
    }
}
