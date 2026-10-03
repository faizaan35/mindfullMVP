package com.mindfull.mindfull

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class ShortFormAccessibilityService : AccessibilityService() {

    companion object {
        @Volatile
        var isServiceEnabled = false
            private set

        private var reelSessionCount = 0
        private var reelSessionTimeMs = 0L
        private var lastReelDetectedTime = 0L

        fun getShortFormStats(): Map<String, Any> {
            return mapOf(
                "isEnabled" to isServiceEnabled,
                "reelCount" to reelSessionCount,
                "estimatedReelMs" to reelSessionTimeMs
            )
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceEnabled = true
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val pkg = event.packageName?.toString() ?: return
        val className = event.className?.toString() ?: ""

        val isReelsOrShorts = when {
            pkg == "com.instagram.android" &&
                    (className.contains("Reel", ignoreCase = true) ||
                            className.contains("Clips", ignoreCase = true)) -> true
            pkg == "com.google.android.youtube" &&
                    (className.contains("Shorts", ignoreCase = true) ||
                            className.contains("Reel", ignoreCase = true)) -> true
            pkg == "com.zhiliaoapp.musically" -> true // TikTok
            else -> false
        }

        if (isReelsOrShorts) {
            val now = System.currentTimeMillis()
            if (now - lastReelDetectedTime > 5000L) {
                reelSessionCount++
                OverlayEventBridge.sendEvent(
                    "short_form_detected",
                    mapOf(
                        "package" to pkg,
                        "sessionIndex" to reelSessionCount,
                        "timestamp" to now
                    )
                )
            }
            reelSessionTimeMs += 1000L
            lastReelDetectedTime = now
        }
    }

    override fun onInterrupt() {
        // Accessibility service interrupted
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceEnabled = false
    }
}
