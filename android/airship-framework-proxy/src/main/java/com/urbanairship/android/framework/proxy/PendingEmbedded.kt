package com.urbanairship.android.framework.proxy

import com.urbanairship.embedded.AirshipEmbeddedInfo
import com.urbanairship.embedded.AirshipEmbeddedObserver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

internal object PendingEmbedded {
    private val dispatcher = CoroutineScope(Dispatchers.Default + SupervisorJob())

    private  val _pending: MutableStateFlow<List<AirshipEmbeddedInfo>> = MutableStateFlow(emptyList())
    val pending: StateFlow<List<AirshipEmbeddedInfo>> =  _pending.asStateFlow()

    init {
        dispatcher.launch {
            AirshipEmbeddedObserver(filter = { true })
                .embeddedViewInfoFlow.collect {
                    _pending.value = it
                }
        }
    }
}
