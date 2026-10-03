package com.mindfull.mindfull

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object OverlayEventBridge : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /**
     * Sends an event to Flutter if EventSink is active.
     */
    fun sendEvent(eventType: String, data: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.let { sink ->
                try {
                    val payload = mutableMapOf<String, Any?>("type" to eventType)
                    payload.putAll(data)
                    sink.success(payload)
                } catch (_: Exception) {
                }
            }
        }
    }
}
