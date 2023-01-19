package com.urbanairship.android.framework.proxy

import com.urbanairship.channel.TagGroupsEditor
import com.urbanairship.json.JsonMap

public enum class TagGroupOperationAction {
    ADD, REMOVE, SET
}

public data class TagGroupOperation(
    public val group: String,
    public val tags: List<String>,
    public val action: TagGroupOperationAction
) {
    public constructor(json: JsonMap) : this(
        group = json.require("group").requireString(),
        tags = json.require("tags").requireList().map { it.requireString() },
        action = TagGroupOperationAction.valueOf(
            json.require("operationType").requireString().uppercase()
        )
    )
}

internal fun TagGroupOperation.applyOperation(editor: TagGroupsEditor) {
    when (this.action) {
        TagGroupOperationAction.ADD -> editor.addTags(this.group, this.tags.toSet())
        TagGroupOperationAction.REMOVE -> editor.removeTags(this.group, this.tags.toSet())
        TagGroupOperationAction.SET -> editor.setTags(this.group, this.tags.toSet())
    }
}
