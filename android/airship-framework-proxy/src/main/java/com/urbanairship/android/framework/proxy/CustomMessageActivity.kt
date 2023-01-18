/* Copyright Urban Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Intent
import android.os.Bundle
import com.urbanairship.messagecenter.MessageActivity

public class CustomMessageActivity : MessageActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        intent?.let {
            if (CustomMessageCenterActivity.CLOSE_MESSAGE_CENTER == it.action) {
                finish()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        if (CustomMessageCenterActivity.CLOSE_MESSAGE_CENTER == intent.action) {
            finish()
        }
    }


}