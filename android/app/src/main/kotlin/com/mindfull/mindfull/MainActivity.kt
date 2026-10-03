package com.mindfull.mindfull

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.mindfull/platform"
    private val EVENT_CHANNEL = "com.mindfull/events"

    private lateinit var usageStatsHelper: UsageStatsHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usageStatsHelper = UsageStatsHelper(this)

        // Setup Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(OverlayEventBridge)

        // Setup Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkUsagePermission" -> {
                        result.success(usageStatsHelper.hasUsagePermission())
                    }
                    "requestUsagePermission" -> {
                        usageStatsHelper.openUsageSettings()
                        result.success(true)
                    }
                    "checkOverlayPermission" -> {
                        val hasOverlay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Settings.canDrawOverlays(this)
                        } else {
                            true
                        }
                        result.success(hasOverlay)
                    }
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                        }
                        result.success(true)
                    }
                    "getTodayUsageStats" -> {
                        val stats = usageStatsHelper.getTodayUsageStats()
                        result.success(stats)
                    }
                    "getPast7DaysStats" -> {
                        val stats = usageStatsHelper.getPast7DaysStats()
                        result.success(stats)
                    }
                    "getInstalledApps" -> {
                        val includeIcons = call.argument<Boolean>("includeIcons") ?: false
                        val apps = usageStatsHelper.getInstalledApps(includeIcons)
                        result.success(apps)
                    }
                    "startOverlayService" -> {
                        val serviceIntent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_START
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    }
                    "stopOverlayService" -> {
                        val serviceIntent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_STOP
                        }
                        startService(serviceIntent)
                        result.success(true)
                    }
                    "isOverlayServiceRunning" -> {
                        result.success(OverlayService.isServiceRunning)
                    }
                    "updateNotchState" -> {
                        val state = call.argument<String>("state")
                        val serviceIntent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_UPDATE_STATE
                            putExtra(OverlayService.EXTRA_STATE, state)
                        }
                        startService(serviceIntent)
                        result.success(true)
                    }
                    "updateNotchSettings" -> {
                        val overlayEnabled = call.argument<Boolean>("overlayEnabled") ?: true
                        val trackedPackages = call.argument<List<String>>("trackedPackages") ?: emptyList()
                        val nudgeThreshold = call.argument<Int>("nudgeThreshold") ?: 20
                        val currentTask = call.argument<String>("currentPrimaryTask") ?: ""
                        val tasks = call.argument<List<String>>("tasks") ?: emptyList()
                        val reflectionQuote = call.argument<String>("reflectionQuote") ?: ""

                        val prefs = getSharedPreferences("mindfull_prefs", Context.MODE_PRIVATE)
                        prefs.edit()
                            .putBoolean("overlay_enabled", overlayEnabled)
                            .putString("tracked_packages", trackedPackages.joinToString(","))
                            .putInt("nudge_threshold_minutes", nudgeThreshold)
                            .putString("current_primary_task", currentTask)
                            .putString("notch_tasks", tasks.joinToString("|||"))
                            .putString("notch_reflection_quote", reflectionQuote)
                            .apply()

                        val serviceIntent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_UPDATE_SETTINGS
                        }
                        startService(serviceIntent)
                        result.success(true)
                    }
                    "checkAccessibilityPermission" -> {
                        result.success(ShortFormAccessibilityService.isServiceEnabled)
                    }
                    "requestAccessibilityPermission" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "getShortFormStats" -> {
                        result.success(ShortFormAccessibilityService.getShortFormStats())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
