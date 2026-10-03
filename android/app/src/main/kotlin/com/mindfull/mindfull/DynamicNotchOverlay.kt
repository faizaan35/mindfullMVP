package com.mindfull.mindfull

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

@SuppressLint("ViewConstructor")
class DynamicNotchOverlay(
    private val context: Context,
    private val onInteraction: (action: String, data: Map<String, Any?>) -> Unit
) {

    enum class State {
        DORMANT,
        APP_DETECTED,
        USAGE_DISPLAY,
        COLLAPSED,
        EXPANDED,
        CONTEXTUAL_NUDGE,
        ASSISTANT_LISTENING,
        ASSISTANT_PROCESSING,
        ASSISTANT_RESPONDING,
        CHECK_IN,
        REFLECTION
    }

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val mainHandler = Handler(Looper.getMainLooper())

    private var currentState = State.DORMANT
    private var isAttached = false

    // Root overlay container
    private val rootView = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
    }

    // Morphing Pill Container
    private val pillContainer = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
    }

    // Internal views
    private val appIconView = ImageView(context)
    private val primaryTextView = TextView(context)
    private val secondaryTextView = TextView(context)
    private val extraContentLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        visibility = View.GONE
    }
    private val actionButtonsLayout = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
        visibility = View.GONE
    }

    private val backgroundDrawable = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        setColor(Color.parseColor("#121214")) // Matte obsidian dark
        setStroke(dpToPx(1), Color.parseColor("#2C2A28")) // Subtle warm outline
        cornerRadius = dpToPx(24).toFloat()
    }

    private val layoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        y = dpToPx(10) // Top offset below cutout/status bar
    }

    private var currentTargetWidth = dpToPx(160)
    private var currentTargetHeight = dpToPx(38)

    // Current app context
    private var currentPackage: String = ""
    private var currentAppName: String = ""
    private var currentSessionMs: Long = 0L
    private var currentTodayMs: Long = 0L

    init {
        setupViews()
    }

    private fun setupViews() {
        pillContainer.background = backgroundDrawable
        pillContainer.setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))

        // App Icon
        appIconView.layoutParams = LinearLayout.LayoutParams(dpToPx(18), dpToPx(18)).apply {
            marginEnd = dpToPx(8)
        }
        appIconView.visibility = View.GONE

        // Primary Text
        primaryTextView.apply {
            setTextColor(Color.parseColor("#F5F2EB"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            maxLines = 1
            gravity = Gravity.CENTER
        }

        // Secondary Text
        secondaryTextView.apply {
            setTextColor(Color.parseColor("#9E988F"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            setPadding(dpToPx(6), 0, 0, 0)
            maxLines = 1
            gravity = Gravity.CENTER
        }

        val textRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            addView(appIconView)
            addView(primaryTextView)
            addView(secondaryTextView)
        }

        pillContainer.addView(textRow)
        rootView.addView(pillContainer)
        rootView.addView(extraContentLayout)
        rootView.addView(actionButtonsLayout)

        // Pill touch listener to expand / toggle
        pillContainer.setOnClickListener {
            onPillClicked()
        }

        rootView.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_OUTSIDE && currentState == State.EXPANDED) {
                transitionTo(State.COLLAPSED)
                true
            } else {
                false
            }
        }
    }

    fun show() {
        if (!isAttached) {
            try {
                windowManager.addView(rootView, layoutParams)
                isAttached = true
            } catch (_: Exception) {
            }
        }
    }

    fun hide() {
        if (isAttached) {
            try {
                windowManager.removeView(rootView)
                isAttached = false
            } catch (_: Exception) {
            }
        }
    }

    private fun onPillClicked() {
        when (currentState) {
            State.COLLAPSED -> transitionTo(State.EXPANDED)
            State.EXPANDED -> transitionTo(State.COLLAPSED)
            State.USAGE_DISPLAY -> transitionTo(State.EXPANDED)
            State.APP_DETECTED -> transitionTo(State.EXPANDED)
            State.CONTEXTUAL_NUDGE -> {
                onInteraction("nudge_clicked", mapOf("package" to currentPackage))
                transitionTo(State.COLLAPSED)
            }
            State.CHECK_IN -> transitionTo(State.EXPANDED)
            State.REFLECTION -> transitionTo(State.COLLAPSED)
            State.ASSISTANT_RESPONDING -> transitionTo(State.COLLAPSED)
            else -> transitionTo(State.EXPANDED)
        }
    }

    /**
     * Updates Notch context when foreground app changes or usage updates.
     */
    fun updateAppContext(
        packageName: String,
        appName: String,
        sessionMs: Long,
        todayMs: Long
    ) {
        val appChanged = (currentPackage != packageName)
        currentPackage = packageName
        currentAppName = appName
        currentSessionMs = sessionMs
        currentTodayMs = todayMs

        if (appChanged) {
            transitionTo(State.APP_DETECTED)
        } else if (currentState == State.APP_DETECTED || currentState == State.USAGE_DISPLAY) {
            refreshTextContent()
        }
    }

    /**
     * Morphing state transition with smooth ValueAnimator.
     */
    fun transitionTo(newState: State, extraPayload: Map<String, Any?> = emptyMap()) {
        currentState = newState
        mainHandler.removeCallbacksAndMessages(null)

        val targetW: Int
        val targetH: Int
        var autoCollapseDelay = 0L

        when (newState) {
            State.DORMANT -> {
                targetW = dpToPx(16)
                targetH = dpToPx(16)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.GONE
                secondaryTextView.visibility = View.GONE
                extraContentLayout.visibility = View.GONE
                actionButtonsLayout.visibility = View.GONE
            }

            State.APP_DETECTED -> {
                targetW = dpToPx(210)
                targetH = dpToPx(38)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.VISIBLE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.VISIBLE

                primaryTextView.text = currentAppName
                secondaryTextView.text = "· ${formatDuration(currentTodayMs)}"

                extraContentLayout.visibility = View.GONE
                actionButtonsLayout.visibility = View.GONE
                autoCollapseDelay = 4500L
            }

            State.USAGE_DISPLAY -> {
                targetW = dpToPx(240)
                targetH = dpToPx(38)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.VISIBLE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.VISIBLE

                primaryTextView.text = currentAppName
                secondaryTextView.text = "${formatDuration(currentTodayMs)} today"

                extraContentLayout.visibility = View.GONE
                actionButtonsLayout.visibility = View.GONE
                autoCollapseDelay = 5000L
            }

            State.COLLAPSED -> {
                targetW = dpToPx(76)
                targetH = dpToPx(26)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.GONE

                primaryTextView.text = formatDuration(currentTodayMs)
                primaryTextView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)

                extraContentLayout.visibility = View.GONE
                actionButtonsLayout.visibility = View.GONE
            }

            State.EXPANDED -> {
                targetW = dpToPx(290)
                targetH = dpToPx(150)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.VISIBLE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.VISIBLE

                primaryTextView.text = currentAppName
                primaryTextView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                secondaryTextView.text = "Today: ${formatDuration(currentTodayMs)}"

                setupExpandedContent()
                extraContentLayout.visibility = View.VISIBLE
                actionButtonsLayout.visibility = View.VISIBLE
            }

            State.CONTEXTUAL_NUDGE -> {
                targetW = dpToPx(300)
                targetH = dpToPx(160)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.VISIBLE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.GONE

                primaryTextView.text = "$currentAppName · ${formatDuration(currentSessionMs)}"

                val taskTitle = (extraPayload["taskTitle"] as? String) ?: "Your planned priority"
                setupNudgeContent(taskTitle)
                extraContentLayout.visibility = View.VISIBLE
                actionButtonsLayout.visibility = View.VISIBLE
                autoCollapseDelay = 12000L
            }

            State.ASSISTANT_LISTENING -> {
                targetW = dpToPx(230)
                targetH = dpToPx(42)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.VISIBLE

                primaryTextView.text = "I'm listening"
                secondaryTextView.text = "● ● ●"

                extraContentLayout.visibility = View.GONE
                actionButtonsLayout.visibility = View.GONE
            }

            State.ASSISTANT_PROCESSING -> {
                targetW = dpToPx(200)
                targetH = dpToPx(40)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.VISIBLE

                primaryTextView.text = "Reflecting"
                secondaryTextView.text = "✦"

                extraContentLayout.visibility = View.GONE
                actionButtonsLayout.visibility = View.GONE
            }

            State.ASSISTANT_RESPONDING -> {
                targetW = dpToPx(280)
                targetH = dpToPx(110)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.GONE

                val message = (extraPayload["message"] as? String) ?: "Task captured."
                primaryTextView.text = "Mindful Assistant"

                setupAssistantResponseContent(message)
                extraContentLayout.visibility = View.VISIBLE
                actionButtonsLayout.visibility = View.GONE
                autoCollapseDelay = 6000L
            }

            State.CHECK_IN -> {
                targetW = dpToPx(280)
                targetH = dpToPx(130)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.GONE

                primaryTextView.text = "Mindful Check-in"
                setupCheckInContent()
                extraContentLayout.visibility = View.VISIBLE
                actionButtonsLayout.visibility = View.VISIBLE
                autoCollapseDelay = 15000L
            }

            State.REFLECTION -> {
                targetW = dpToPx(280)
                targetH = dpToPx(100)
                pillContainer.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.GONE

                val quote = (extraPayload["quote"] as? String)
                    ?: "Attention is your most sacred non-renewable resource."
                primaryTextView.text = "Pause & Reflect"
                setupReflectionContent(quote)
                extraContentLayout.visibility = View.VISIBLE
                actionButtonsLayout.visibility = View.GONE
                autoCollapseDelay = 8000L
            }
        }

        animateDimensions(targetW, targetH)

        if (autoCollapseDelay > 0) {
            mainHandler.postDelayed({
                if (currentState == newState) {
                    transitionTo(State.COLLAPSED)
                }
            }, autoCollapseDelay)
        }

        // Notify Flutter
        OverlayEventBridge.sendEvent(
            "notch_state_changed",
            mapOf("state" to newState.name, "packageName" to currentPackage)
        )
    }

    private fun refreshTextContent() {
        when (currentState) {
            State.APP_DETECTED -> {
                primaryTextView.text = currentAppName
                secondaryTextView.text = "· ${formatDuration(currentTodayMs)}"
            }
            State.USAGE_DISPLAY -> {
                primaryTextView.text = currentAppName
                secondaryTextView.text = "${formatDuration(currentTodayMs)} today"
            }
            State.COLLAPSED -> {
                primaryTextView.text = formatDuration(currentTodayMs)
            }
            State.EXPANDED -> {
                primaryTextView.text = currentAppName
                secondaryTextView.text = "Today: ${formatDuration(currentTodayMs)}"
            }
            else -> {}
        }
    }

    private fun animateDimensions(targetWidth: Int, targetHeight: Int) {
        val startW = currentTargetWidth
        val startH = currentTargetHeight
        currentTargetWidth = targetWidth
        currentTargetHeight = targetHeight

        val animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 320L
            interpolator = DecelerateInterpolator(1.8f)
            addUpdateListener { anim ->
                val fraction = anim.animatedFraction
                val currW = (startW + (targetWidth - startW) * fraction).toInt()
                val currH = (startH + (targetHeight - startH) * fraction).toInt()

                pillContainer.layoutParams = LinearLayout.LayoutParams(currW, currH)
                val radius = (currH / 2f).coerceAtMost(dpToPx(28).toFloat())
                backgroundDrawable.cornerRadius = radius

                if (isAttached) {
                    try {
                        windowManager.updateViewLayout(rootView, layoutParams)
                    } catch (_: Exception) {
                    }
                }
            }
        }
        animator.start()
    }

    // --- Content Setups ---

    private fun setupExpandedContent() {
        extraContentLayout.removeAllViews()
        actionButtonsLayout.removeAllViews()

        val sessionStats = TextView(context).apply {
            text = "Session duration: ${formatDuration(currentSessionMs)}"
            setTextColor(Color.parseColor("#C4BEB5"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding(0, dpToPx(6), 0, dpToPx(8))
        }
        extraContentLayout.addView(sessionStats)

        // Intentional vs Unintentional buttons
        val intentionalBtn = createPillButton("Intentional", "#2D4A3E") {
            onInteraction("classify_session", mapOf("package" to currentPackage, "intentional" to true))
            transitionTo(State.COLLAPSED)
        }
        val unintentionalBtn = createPillButton("Unintentional", "#4A2D30") {
            onInteraction("classify_session", mapOf("package" to currentPackage, "intentional" to false))
            transitionTo(State.COLLAPSED)
        }
        val closeBtn = createPillButton("Dismiss", "#252422") {
            transitionTo(State.COLLAPSED)
        }

        actionButtonsLayout.addView(intentionalBtn)
        actionButtonsLayout.addView(unintentionalBtn)
        actionButtonsLayout.addView(closeBtn)
    }

    private fun setupNudgeContent(taskTitle: String) {
        extraContentLayout.removeAllViews()
        actionButtonsLayout.removeAllViews()

        val promptText = TextView(context).apply {
            text = "You planned to work on:\n\"$taskTitle\"\nBack to it?"
            setTextColor(Color.parseColor("#EBE6DC"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(6))
        }
        extraContentLayout.addView(promptText)

        val backToTaskBtn = createPillButton("Back to Task", "#3B5342") {
            onInteraction("nudge_action_return", mapOf("package" to currentPackage))
            transitionTo(State.COLLAPSED)
        }
        val stayBtn = createPillButton("Stay 5m", "#262524") {
            onInteraction("nudge_action_snooze", mapOf("package" to currentPackage))
            transitionTo(State.COLLAPSED)
        }

        actionButtonsLayout.addView(backToTaskBtn)
        actionButtonsLayout.addView(stayBtn)
    }

    private fun setupCheckInContent() {
        extraContentLayout.removeAllViews()
        actionButtonsLayout.removeAllViews()

        val question = TextView(context).apply {
            text = "How does your attention feel right now?"
            setTextColor(Color.parseColor("#E8E2D7"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding(0, dpToPx(4), 0, dpToPx(6))
        }
        extraContentLayout.addView(question)

        val moodGood = createPillButton("Focused 🙂", "#2D4A3E") {
            onInteraction("check_in_response", mapOf("mood" to "focused", "score" to 5))
            transitionTo(State.COLLAPSED)
        }
        val moodNeutral = createPillButton("Wandering 😐", "#3D382B") {
            onInteraction("check_in_response", mapOf("mood" to "wandering", "score" to 3))
            transitionTo(State.COLLAPSED)
        }
        val moodDistracted = createPillButton("Distracted 😔", "#4A2D30") {
            onInteraction("check_in_response", mapOf("mood" to "distracted", "score" to 1))
            transitionTo(State.COLLAPSED)
        }

        actionButtonsLayout.addView(moodGood)
        actionButtonsLayout.addView(moodNeutral)
        actionButtonsLayout.addView(moodDistracted)
    }

    private fun setupReflectionContent(quote: String) {
        extraContentLayout.removeAllViews()
        val quoteView = TextView(context).apply {
            text = "\"$quote\""
            setTextColor(Color.parseColor("#DED9CE"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setPadding(dpToPx(8), dpToPx(6), dpToPx(8), dpToPx(6))
        }
        extraContentLayout.addView(quoteView)
    }

    private fun setupAssistantResponseContent(message: String) {
        extraContentLayout.removeAllViews()
        val respView = TextView(context).apply {
            text = message
            setTextColor(Color.parseColor("#E8E3D8"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(6))
        }
        extraContentLayout.addView(respView)
    }

    private fun createPillButton(text: String, bgColor: String, onClick: () -> Unit): Button {
        return Button(context).apply {
            this.text = text
            setTextColor(Color.parseColor("#F5F2EB"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            isAllCaps = false
            minHeight = 0
            minimumHeight = 0
            minWidth = 0
            minimumWidth = 0
            setPadding(dpToPx(10), dpToPx(4), dpToPx(10), dpToPx(4))
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor(bgColor))
                cornerRadius = dpToPx(14).toFloat()
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                marginStart = dpToPx(4)
                marginEnd = dpToPx(4)
            }
            setOnClickListener { onClick() }
        }
    }

    private fun formatDuration(millis: Long): String {
        val totalSecs = millis / 1000
        val mins = totalSecs / 60
        val hours = mins / 60
        return when {
            hours > 0 -> "${hours}h ${mins % 60}m"
            mins > 0 -> "${mins}m"
            else -> "<1m"
        }
    }

    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            context.resources.displayMetrics
        ).toInt()
    }
}
