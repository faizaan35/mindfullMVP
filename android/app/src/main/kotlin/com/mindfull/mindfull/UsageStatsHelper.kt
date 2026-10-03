package com.mindfull.mindfull

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.util.Calendar

class UsageStatsHelper(private val context: Context) {

    private val usageStatsManager =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

    /**
     * Checks if PACKAGE_USAGE_STATS permission has been granted.
     */
    fun hasUsagePermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Opens the system Usage Access Settings.
     */
    fun openUsageSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    /**
     * Detects the current foreground package name using UsageEvents over the last 15 seconds.
     */
    fun getForegroundApp(): String? {
        if (!hasUsagePermission()) return null

        val endTime = System.currentTimeMillis()
        val startTime = endTime - 15_000 // lookback 15 seconds
        val events = usageStatsManager.queryEvents(startTime, endTime)
        var lastResumedPkg: String? = null
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                lastResumedPkg = event.packageName
            }
        }
        return lastResumedPkg
    }

    /**
     * Calculates today's usage statistics from midnight to now.
     */
    fun getTodayUsageStats(): Map<String, Any> {
        if (!hasUsagePermission()) {
            return mapOf(
                "totalTimeMs" to 0L,
                "appStats" to emptyList<Map<String, Any>>()
            )
        }

        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        return getUsageStatsForRange(startTime, endTime)
    }

    /**
     * Calculates past 7 days usage history (day by day).
     */
    fun getPast7DaysStats(): List<Map<String, Any>> {
        if (!hasUsagePermission()) return emptyList()

        val results = mutableListOf<Map<String, Any>>()
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        // 7 days including today
        for (i in 6 downTo 0) {
            val dayCal = calendar.clone() as Calendar
            dayCal.add(Calendar.DAY_OF_YEAR, -i)
            val dayStart = dayCal.timeInMillis
            val dayEnd = dayStart + 24 * 60 * 60 * 1000 - 1

            val stats = getUsageStatsForRange(dayStart, minOf(dayEnd, System.currentTimeMillis()))
            results.add(
                mapOf(
                    "timestamp" to dayStart,
                    "dateStr" to String.format(
                        "%04d-%02d-%02d",
                        dayCal.get(Calendar.YEAR),
                        dayCal.get(Calendar.MONTH) + 1,
                        dayCal.get(Calendar.DAY_OF_MONTH)
                    ),
                    "dayOfWeek" to dayCal.get(Calendar.DAY_OF_WEEK),
                    "totalTimeMs" to (stats["totalTimeMs"] ?: 0L),
                    "appCount" to ((stats["appStats"] as? List<*>)?.size ?: 0)
                )
            )
        }
        return results
    }

    /**
     * Calculates aggregated usage statistics for a specific time range.
     */
    fun getUsageStatsForRange(startTime: Long, endTime: Long): Map<String, Any> {
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        var totalTimeMs = 0L
        val appList = mutableListOf<Map<String, Any>>()
        val pm = context.packageManager

        // Group and sum in case multiple buckets are returned
        val grouped = mutableMapOf<String, Long>()
        var lastUsedMap = mutableMapOf<String, Long>()

        for (stat in usageStats) {
            val time = stat.totalTimeInForeground
            if (time > 0) {
                grouped[stat.packageName] = (grouped[stat.packageName] ?: 0L) + time
                val lastUsed = stat.lastTimeUsed
                if (lastUsed > (lastUsedMap[stat.packageName] ?: 0L)) {
                    lastUsedMap[stat.packageName] = lastUsed
                }
            }
        }

        for ((pkg, time) in grouped) {
            // Filter out system launchers and mindfull self if desired
            if (pkg == context.packageName) continue

            totalTimeMs += time
            var appName = pkg
            try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                appName = pm.getApplicationLabel(appInfo).toString()
            } catch (_: PackageManager.NameNotFoundException) {
            }

            appList.add(
                mapOf(
                    "packageName" to pkg,
                    "appName" to appName,
                    "totalTimeMs" to time,
                    "lastTimeUsed" to (lastUsedMap[pkg] ?: 0L)
                )
            )
        }

        appList.sortByDescending { it["totalTimeMs"] as Long }

        return mapOf(
            "startTime" to startTime,
            "endTime" to endTime,
            "totalTimeMs" to totalTimeMs,
            "appStats" to appList
        )
    }

    /**
     * Returns a list of installed launcher apps with package name, display name, and base64 icon.
     */
    fun getInstalledApps(includeIcons: Boolean = false): List<Map<String, Any>> {
        val pm = context.packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
        val installedApps = mutableListOf<Map<String, Any>>()
        val seenPackages = mutableSetOf<String>()

        for (resolveInfo in resolveInfos) {
            val pkg = resolveInfo.activityInfo.packageName
            if (pkg == context.packageName || seenPackages.contains(pkg)) continue
            seenPackages.add(pkg)

            val label = resolveInfo.loadLabel(pm).toString()
            val isSystem = (resolveInfo.activityInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

            val appData = mutableMapOf<String, Any>(
                "packageName" to pkg,
                "appName" to label,
                "isSystem" to isSystem
            )

            if (includeIcons) {
                try {
                    val iconDrawable = resolveInfo.loadIcon(pm)
                    val base64Icon = drawableToBase64(iconDrawable)
                    if (base64Icon != null) {
                        appData["iconBase64"] = base64Icon
                    }
                } catch (_: Exception) {
                }
            }

            installedApps.add(appData)
        }

        installedApps.sortBy { (it["appName"] as String).lowercase() }
        return installedApps
    }

    /**
     * Converts a Drawable to a PNG Base64 string for Flutter rendering.
     */
    fun drawableToBase64(drawable: Drawable): String? {
        return try {
            val bitmap = when (drawable) {
                is BitmapDrawable -> drawable.bitmap
                else -> {
                    val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
                    val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
                    val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bmp)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bmp
                }
            }
            val scaled = Bitmap.createScaledBitmap(bitmap, 72, 72, true)
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.PNG, 90, stream)
            Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
        } catch (_: Exception) {
            null
        }
    }
}
