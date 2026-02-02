package com.urbanairship.android.framework.proxy.proxies

import com.urbanairship.UALog
import com.urbanairship.json.JsonException
import com.urbanairship.json.JsonMap
import com.urbanairship.json.JsonSerializable
import com.urbanairship.json.JsonValue
import com.urbanairship.json.jsonMapOf
import com.urbanairship.json.optionalField
import com.urbanairship.json.requireField
import com.urbanairship.liveupdate.LiveUpdate
import com.urbanairship.liveupdate.LiveUpdateManager
import com.urbanairship.util.DateUtils

public class LiveUpdatesManagerProxy(private val managerProvider: () -> LiveUpdateManager) {

    private val manager: LiveUpdateManager
        get() {
            return managerProvider()
        }

    public suspend fun list(request: LiveUpdateRequest.List): List<LiveUpdateProxy> {
        UALog.v { "list called, type=${request.type}" }
        return this.manager.getAllActiveUpdates().filter { it.type == request.type }.map { LiveUpdateProxy(it) }
    }

    public suspend fun listAll(): List<LiveUpdateProxy> {
        UALog.v { "listAll called" }
        return this.manager.getAllActiveUpdates().map { LiveUpdateProxy(it) }
    }

    public fun start(request: LiveUpdateRequest.Start) {
        UALog.v { "start called, name=${request.name}, type=${request.type}" }
        this.manager.start(
            name = request.name,
            type = request.type,
            content = request.content,
            timestamp = request.timestamp ?: System.currentTimeMillis(),
            dismissTimestamp = request.dismissalTimestamp
        )
    }

    public fun update(request: LiveUpdateRequest.Update) {
        UALog.v { "update called, name=${request.name}" }
        this.manager.update(
            name = request.name,
            content = request.content,
            timestamp = request.timestamp ?: System.currentTimeMillis(),
            dismissTimestamp = request.dismissalTimestamp
        )
    }

    public fun end(request: LiveUpdateRequest.End) {
        UALog.v { "end called, name=${request.name}" }
        this.manager.end(
            name = request.name,
            content = request.content,
            timestamp = request.timestamp ?: System.currentTimeMillis(),
            dismissTimestamp = request.dismissalTimestamp
        )
    }

    public fun clearAll() {
        UALog.v { "clearAll called" }
        this.manager.clearAll()
    }
}

public class LiveUpdateProxy(private val liveUpdate: LiveUpdate): JsonSerializable {
    override fun toJsonValue(): JsonValue {
        return jsonMapOf(
            "name" to liveUpdate.name,
            "type" to liveUpdate.type,
            "content" to liveUpdate.content,
            "lastContentUpdateTimestamp" to liveUpdate.lastContentUpdateTime.let { DateUtils.createIso8601TimeStamp(it) },
            "lastStateChangeTimestamp" to liveUpdate.lastStateChangeTime.let { DateUtils.createIso8601TimeStamp(it) },
            "dismissTimestamp" to liveUpdate.dismissalTime?.let { DateUtils.createIso8601TimeStamp(it) }
        ).toJsonValue()
    }
}

public sealed class LiveUpdateRequest {

    public data class Update(
        val name: String,
        val content: JsonMap,
        val timestamp: Long? = null,
        val dismissalTimestamp: Long? = null
    ): LiveUpdateRequest() {
        public companion object {
            @Throws(JsonException::class)
            public fun fromJson(jsonValue: JsonValue): Update {
                val map = jsonValue.requireMap()
                return Update(
                    name = map.requireField(NAME),
                    content = map.requireField(CONTENT),
                    timestamp =  map.optionalField<String>(TIMESTAMP)?.let {
                        DateUtils.parseIso8601(it)
                    },
                    dismissalTimestamp = map.optionalField<String>(DISMISSAL_TIMESTAMP)?.let {
                        DateUtils.parseIso8601(it)
                    }
                )
            }
        }
    }

    public data class End(
        val name: String,
        val content: JsonMap?,
        val timestamp: Long? = null,
        val dismissalTimestamp: Long? = null
    ): LiveUpdateRequest() {
        public companion object {
            @Throws(JsonException::class)
            public fun fromJson(jsonValue: JsonValue): End {
                val map = jsonValue.requireMap()
                return End(
                    name = map.requireField(NAME),
                    content = map.optionalField(CONTENT),
                    timestamp =  map.optionalField<String>(TIMESTAMP)?.let {
                        DateUtils.parseIso8601(it)
                    },
                    dismissalTimestamp = map.optionalField<String>(DISMISSAL_TIMESTAMP)?.let {
                        DateUtils.parseIso8601(it)
                    }
                )
            }
        }
    }

    public data class Start(
        val name: String,
        val type: String,
        val content: JsonMap,
        val timestamp: Long? = null,
        val dismissalTimestamp: Long? = null
    ): LiveUpdateRequest() {
        public companion object {
            @Throws(JsonException::class)
            public fun fromJson(jsonValue: JsonValue): Start {
                val map = jsonValue.requireMap()
                return Start(
                    name = map.requireField(NAME),
                    type = map.requireField(TYPE),
                    content = map.requireField(CONTENT),
                    timestamp =  map.optionalField<String>(TIMESTAMP)?.let {
                        DateUtils.parseIso8601(it)
                    },
                    dismissalTimestamp = map.optionalField<String>(DISMISSAL_TIMESTAMP)?.let {
                        DateUtils.parseIso8601(it)
                    }
                )
            }
        }
    }

    public data class List(
        val type: String
    ): LiveUpdateRequest() {
        public companion object {
            @Throws(JsonException::class)
            public fun fromJson(jsonValue: JsonValue): List {
                val map = jsonValue.requireMap()
                return List(
                    type = map.requireField(TYPE)
                )
            }
        }
    }

    private companion object {
        const val NAME = "name"
        const val TYPE = "type"
        const val CONTENT = "content"
        const val TIMESTAMP = "timestamp"
        const val DISMISSAL_TIMESTAMP = "dismissalTimestamp"
    }
}
