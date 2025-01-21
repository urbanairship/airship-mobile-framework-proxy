/* Copyright Airship and Contributors */

package com.urbanairship.android.framework.proxy

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.ViewGroup
import androidx.activity.enableEdgeToEdge
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.commitNow
import androidx.lifecycle.lifecycleScope
import com.urbanairship.Autopilot
import com.urbanairship.UALog
import com.urbanairship.UAirship
import com.urbanairship.android.framework.proxy.proxies.AirshipProxy
import com.urbanairship.messagecenter.MessageCenter
import com.urbanairship.messagecenter.ui.MessageCenterFragment
import kotlinx.coroutines.launch

public class CustomMessageCenterActivity : FragmentActivity() {

    private lateinit var messageCenterFragment: MessageCenterFragment

    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge to edge
        enableEdgeToEdge()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }

        super.onCreate(savedInstanceState)
        Autopilot.automaticTakeOff(application)

        if (!UAirship.isTakingOff() && !UAirship.isFlying()) {
            UALog.e("MessageCenterActivity - unable to create activity, takeOff not called.")
            finish()
            return
        }

        var fragment: MessageCenterFragment? = null

        if (savedInstanceState != null) {
            fragment =
                supportFragmentManager.findFragmentByTag(FRAGMENT_TAG) as? MessageCenterFragment
        }

        if (fragment == null) {
            fragment = MessageCenterFragment.newInstance(MessageCenter.parseMessageId(intent))

            supportFragmentManager.commitNow {
                add(android.R.id.content, fragment, FRAGMENT_TAG)
            }
        }

        messageCenterFragment = fragment

        // Apply the default message center predicate
        messageCenterFragment.listPredicate = MessageCenter.shared().predicate

        val contentView = findViewById<ViewGroup>(android.R.id.content)

        ViewCompat.setOnApplyWindowInsetsListener(contentView) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            contentView.setPadding(systemBars.left, systemBars.right, systemBars.left, systemBars.bottom)
            insets
        }

        ViewCompat.requestApplyInsets(contentView)

        val messageCenter = AirshipProxy.shared(this).messageCenter
        this.lifecycleScope.launch {
            messageCenter.displayState.collect { display ->
                if (!display) {
                    finish()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        MessageCenter.parseMessageId(intent)?.let(messageCenterFragment::showMessage)
    }

    internal companion object {
        private const val FRAGMENT_TAG = "MESSAGE_CENTER_FRAGMENT"
    }
}
