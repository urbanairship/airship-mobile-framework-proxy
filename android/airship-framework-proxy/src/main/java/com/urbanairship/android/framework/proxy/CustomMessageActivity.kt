/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.os.Bundle
import androidx.lifecycle.lifecycleScope
import com.urbanairship.android.framework.proxy.proxies.AirshipProxy
import com.urbanairship.messagecenter.ui.MessageActivity
import kotlinx.coroutines.launch

public class CustomMessageActivity : MessageActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val messageCenter = AirshipProxy.shared(this).messageCenter
        this.lifecycleScope.launch {
            messageCenter.displayState.collect { display ->
                if (!display) {
                    finish()
                }
            }
        }
    }
}
