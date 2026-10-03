package com.mindfull.mindfull

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import androidx.core.app.NotificationCompat

class OverlayService : Service() {

    companion object {
        const val CHANNEL_ID = "mindfull_overlay_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_START = "com.mindfull.mindfull.ACTION_START"
        const val ACTION_STOP = "com.mindfull.mindfull.ACTION_STOP"
        const val ACTION_UPDATE_STATE = "com.mindfull.mindfull.ACTION_UPDATE_STATE"
        const val ACTION_UPDATE_SETTINGS = "com.mindfull.mindfull.ACTION_UPDATE_SETTINGS"

        const val EXTRA_STATE = "extra_state"
        const val EXTRA_PAYLOAD = "extra_payload"

        @Volatile
        var isServiceRunning = false
            private set
    }

    private lateinit var usageStatsHelper: UsageStatsHelper
    private lateinit var prefs: SharedPreferences
    private var overlay: DynamicNotchOverlay? = null

    private val monitorHandler = Handler(Looper.getMainLooper())
    private var currentForegroundPackage: String? = null
    private var sessionStartTime: Long = 0L

    // Configurable settings
    private var overlayEnabled = true
    private var trackedPackages = setOf<String>()
    private var nudgeThresholdMinutes = 20

    private val monitorRunnable = object : Runnable {
        override fun run() {
            if (isServiceRunning && overlayEnabled) {
                checkForegroundApp()
            }
            monitorHandler.postDelayed(this, 1800L) // Mindful 1.8s polling interval (low battery impact)
        }
    }

    override fun onCreate() {
        super.onCreate()
        usageStatsHelper = UsageStatsHelper(this)
        prefs = getSharedPreferences("mindfull_prefs", Context.MODE_PRIVATE)
        loadSettings()

        createNotificationChannel()
        startForegroundWithNotification()

        if (Settings.canDrawOverlays(this)) {
            overlay = DynamicNotchOverlay(this) { action, data ->
                handleOverlayInteraction(action, data)
            }
            if (overlayEnabled) {
                overlay?.show()
            }
        }

        isServiceRunning = true
        monitorHandler.post(monitorRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_UPDATE_STATE -> {
                val stateName = intent.getStringExtra(EXTRA_STATE)
                if (stateName != null) {
                    try {
                        val state = DynamicNotchOverlay.State.valueOf(stateName)
                        overlay?.transitionTo(state)
                    } catch (_: Exception) {
                    }
                }
            }
            ACTION_UPDATE_SETTINGS -> {
                loadSettings()
            }
        }
        return START_STICKY
    }

    private fun checkForegroundApp() {
        val newPkg = usageStatsHelper.getForegroundApp() ?: return
        val now = System.currentTimeMillis()

        if (newPkg != currentForegroundPackage) {
            // App switched!
            val oldPkg = currentForegroundPackage
            val oldSessionDuration = if (sessionStartTime > 0) now - sessionStartTime else 0L

            if (oldPkg != null && oldSessionDuration > 1000L) {
                // Inform Flutter of completed session
                OverlayEventBridge.sendEvent(
                    "session_completed",
                    mapOf(
                        "packageName" to oldPkg,
                        "startedAt" to sessionStartTime,
                        "endedAt" to now,
                        "durationMs" to oldSessionDuration
                    )
                )
            }

            currentForegroundPackage = newPkg
            sessionStartTime = now

            // If tracked app or any app (when tracking list is empty, tracks all interactive apps)
            val shouldTrack = trackedPackages.isEmpty() || trackedPackages.contains(newPkg)
            if (shouldTrack && newPkg != packageName) {
                val appName = getAppLabel(newPkg)
                val todayStats = usageStatsHelper.getTodayUsageStats()
                val appStatsList = (todayStats["appStats"] as? List<Map<String, Any>>) ?: emptyList()
                val todayMs = appStatsList.firstOrNull { it["packageName"] == newPkg }?.get("totalTimeMs") as? Long ?: 0L

                overlay?.updateAppContext(
                    packageName = newPkg,
                    appName = appName,
                    sessionMs = 0L,
                    todayMs = todayMs
                )

                OverlayEventBridge.sendEvent(
                    "app_resumed",
                    mapOf(
                        "packageName" to newPkg,
                        "appName" to appName,
                        "timestamp" to now,
                        "todayMs" to todayMs
                    )
                )
            }
        } else {
            // Still in the same app: update session time
            val sessionMs = now - sessionStartTime
            // Check for contextual nudge threshold
            if (nudgeThresholdMinutes > 0 &&
                sessionMs >= (nudgeThresholdMinutes * 60 * 1000L) &&
                sessionMs < (nudgeThresholdMinutes * 60 * 1000L + 3000L)
            ) {
                overlay?.transitionTo(
                    DynamicNotchOverlay.State.CONTEXTUAL_NUDGE,
                    mapOf("taskTitle" to prefs.getString("current_primary_task", "Your intended focus"))
                )
            }
        }
    }

    private fun handleOverlayInteraction(action: String, data: Map<String, Any?>) {
        OverlayEventBridge.sendEvent(action, data)
        when (action) {
            "nudge_action_return" -> {
                // Launch Mindfull app
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                }
                if (launchIntent != null) {
                    startActivity(launchIntent)
                }
            }
            "classify_session" -> {
                // Session classification
                OverlayEventBridge.sendEvent("session_classified", data)
            }
        }
    }

    private fun loadSettings() {
        overlayEnabled = prefs.getBoolean("overlay_enabled", true)
        val trackedStr = prefs.getString("tracked_packages", "") ?: ""
        trackedPackages = if (trackedStr.isEmpty()) emptySet() else trackedStr.split(",").toSet()
        nudgeThresholdMinutes = prefs.getInt("nudge_threshold_minutes", 20)

        if (!overlayEnabled) {
            overlay?.hide()
        } else {
            overlay?.show()
        }
    }

    private fun getAppLabel(pkg: String): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(pkg, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            pkg
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mindfull Attention Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows the active Dynamic Notch awareness indicator"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Mindfull")
            .setContentText("Attention companion active")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        monitorHandler.removeCallbacksAndMessages(null)
        overlay?.hide()
        overlay = null
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
