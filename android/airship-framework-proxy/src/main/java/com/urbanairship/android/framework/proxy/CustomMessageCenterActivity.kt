/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import com.urbanairship.messagecenter.MessageCenterActivity
import android.os.Bundle
import android.content.Intent

public class CustomMessageCenterActivity : MessageCenterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        intent?.let {
            if (CLOSE_MESSAGE_CENTER == it.action) {
                finish()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        if (CLOSE_MESSAGE_CENTER == intent.action) {
            finish()
        }
    }

    internal companion object {
        internal const val CLOSE_MESSAGE_CENTER: String = "CLOSE"
    }
}