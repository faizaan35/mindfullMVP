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
import kotlin.math.abs

@SuppressLint("ViewConstructor", "ClickableViewAccessibility")
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

    // Root overlay container attached to WindowManager
    private val rootView = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
    }

    // Morphing Pill Container - ENCLOSES ALL NOTCH CONTENT COMPLETELY
    private val pillContainer = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
    }

    // Top Header Row (always top of pill)
    private val headerRow = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
    }
    private val appIconView = ImageView(context)
    private val primaryTextView = TextView(context)
    private val secondaryTextView = TextView(context)

    // Expanded Multi-Page Carousel Container (inside pill)
    private val carouselContainer = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        visibility = View.GONE
    }

    // Page 0: Usage Details
    private val pageUsageLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
    }
    private val usageSessionTextView = TextView(context)
    private val usageActionsLayout = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
    }

    // Page 1: Tasks
    private val pageTasksLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
    }
    private val tasksHeaderView = TextView(context)
    private val tasksItemsLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.START
    }

    // Page 2: Mindfulness & Reflection
    private val pageReflectionLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
    }
    private val reflectionHeaderView = TextView(context)
    private val reflectionQuoteTextView = TextView(context)

    // Bottom Navigation Dots & Hint (inside pill)
    private val footerLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
    }
    private val dotsLayout = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
    }
    private val dotViews = ArrayList<View>()
    private val swipeHintTextView = TextView(context)

    // Special Event Layout (for Nudge, Check-in, Assistant)
    private val specialContentLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        visibility = View.GONE
    }

    private val backgroundDrawable = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        setColor(Color.parseColor("#142907")) // Wise Forest obsidian dark
        setStroke(dpToPx(1), Color.parseColor("#2D4A18")) // Subtle Wise Lime border
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
    private var currentAppName: String = "Mindful"
    private var currentSessionMs: Long = 0L
    private var currentTodayMs: Long = 0L

    // Carousel state
    private var currentCarouselPage = 0
    private var activeTasks: List<String> = emptyList()
    private var reflectionQuote: String = "The attention you give something is the life you give it."

    // Gesture tracking variables
    private var touchStartX = 0f
    private var touchStartY = 0f
    private var touchStartTime = 0L

    init {
        setupViews()
        setupTouchGestures()
    }

    private fun setupViews() {
        pillContainer.background = backgroundDrawable
        pillContainer.setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))

        // App Icon
        appIconView.layoutParams = LinearLayout.LayoutParams(dpToPx(16), dpToPx(16)).apply {
            marginEnd = dpToPx(7)
        }
        appIconView.visibility = View.GONE

        // Primary Text
        primaryTextView.apply {
            setTextColor(Color.parseColor("#FAF9F6"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            maxLines = 1
            gravity = Gravity.CENTER
        }

        // Secondary Text
        secondaryTextView.apply {
            setTextColor(Color.parseColor("#9FE870")) // Wise Lime
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            setPadding(dpToPx(6), 0, 0, 0)
            maxLines = 1
            gravity = Gravity.CENTER
        }

        headerRow.apply {
            addView(appIconView)
            addView(primaryTextView)
            addView(secondaryTextView)
        }
        pillContainer.addView(headerRow)

        // 1. Page Usage
        usageSessionTextView.apply {
            setTextColor(Color.parseColor("#C8D4C0"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(6), 0, dpToPx(8))
        }
        pageUsageLayout.addView(usageSessionTextView)
        pageUsageLayout.addView(usageActionsLayout)

        // 2. Page Tasks
        tasksHeaderView.apply {
            text = "TODAY'S PRIORITIES"
            setTextColor(Color.parseColor("#9FE870"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(4), 0, dpToPx(6))
        }
        pageTasksLayout.addView(tasksHeaderView)
        pageTasksLayout.addView(tasksItemsLayout)

        // 3. Page Reflection
        reflectionHeaderView.apply {
            text = "PAUSE & REFLECT"
            setTextColor(Color.parseColor("#9FE870"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(4), 0, dpToPx(4))
        }
        reflectionQuoteTextView.apply {
            setTextColor(Color.parseColor("#FAF9F6"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.create("sans-serif", Typeface.ITALIC)
            gravity = Gravity.CENTER
            maxLines = 3
            setPadding(dpToPx(12), dpToPx(4), dpToPx(12), dpToPx(6))
        }
        pageReflectionLayout.addView(reflectionHeaderView)
        pageReflectionLayout.addView(reflectionQuoteTextView)

        // Assemble Carousel
        carouselContainer.addView(pageUsageLayout)
        carouselContainer.addView(pageTasksLayout)
        carouselContainer.addView(pageReflectionLayout)

        // Dots & Swipe Hint
        setupDots()
        swipeHintTextView.apply {
            setTextColor(Color.parseColor("#7A8A74"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 9.5f)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(4), 0, dpToPx(2))
        }
        footerLayout.addView(dotsLayout)
        footerLayout.addView(swipeHintTextView)
        carouselContainer.addView(footerLayout)

        pillContainer.addView(carouselContainer)
        pillContainer.addView(specialContentLayout)

        // ROOT VIEW contains ONLY pillContainer - Everything enclosed inside the pill!
        rootView.addView(pillContainer)
    }

    private fun setupDots() {
        dotsLayout.removeAllViews()
        dotViews.clear()
        for (i in 0..2) {
            val dot = View(context).apply {
                val size = dpToPx(5)
                layoutParams = LinearLayout.LayoutParams(size, size).apply {
                    setMargins(dpToPx(3), dpToPx(4), dpToPx(3), dpToPx(2))
                }
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(if (i == 0) Color.parseColor("#9FE870") else Color.parseColor("#3C4E36"))
                }
            }
            dotsLayout.addView(dot)
            dotViews.add(dot)
        }
    }

    private fun updateDotIndicators(activeIndex: Int) {
        for (i in dotViews.indices) {
            val dot = dotViews[i]
            val bg = dot.background as? GradientDrawable ?: continue
            if (i == activeIndex) {
                bg.setColor(Color.parseColor("#9FE870")) // Active Wise Lime
            } else {
                bg.setColor(Color.parseColor("#3C4E36")) // Inactive Forest Subtle
            }
        }
    }

    private fun setupTouchGestures() {
        pillContainer.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    touchStartX = event.x
                    touchStartY = event.y
                    touchStartTime = System.currentTimeMillis()
                    true
                }

                MotionEvent.ACTION_UP -> {
                    val deltaX = event.x - touchStartX
                    val deltaY = event.y - touchStartY
                    val duration = System.currentTimeMillis() - touchStartTime

                    val isTap = abs(deltaX) < dpToPx(14) && abs(deltaY) < dpToPx(14) && duration < 320

                    if (isTap) {
                        onPillTapped()
                        true
                    } else if (currentState == State.EXPANDED) {
                        // Gesture swipe detection
                        if (abs(deltaX) > dpToPx(28) && abs(deltaX) > abs(deltaY)) {
                            if (deltaX < 0) {
                                // Swipe LEFT -> next page
                                if (currentCarouselPage < 2) {
                                    currentCarouselPage++
                                    renderCarouselPage(currentCarouselPage)
                                }
                            } else {
                                // Swipe RIGHT -> previous page
                                if (currentCarouselPage > 0) {
                                    currentCarouselPage--
                                    renderCarouselPage(currentCarouselPage)
                                }
                            }
                            true
                        } else if (deltaY < -dpToPx(30)) {
                            // Swipe UP -> collapse
                            transitionTo(State.COLLAPSED)
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    }
                }

                else -> false
            }
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

    private fun onPillTapped() {
        when (currentState) {
            State.COLLAPSED, State.APP_DETECTED, State.USAGE_DISPLAY -> {
                currentCarouselPage = 0
                transitionTo(State.EXPANDED)
            }
            State.EXPANDED -> {
                transitionTo(State.COLLAPSED)
            }
            State.CONTEXTUAL_NUDGE -> {
                onInteraction("nudge_clicked", mapOf("package" to currentPackage))
                transitionTo(State.COLLAPSED)
            }
            State.CHECK_IN, State.REFLECTION, State.ASSISTANT_RESPONDING -> {
                transitionTo(State.COLLAPSED)
            }
            else -> {
                currentCarouselPage = 0
                transitionTo(State.EXPANDED)
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

    fun updateMindfulContent(tasks: List<String>, quote: String) {
        activeTasks = tasks
        if (quote.isNotBlank()) {
            reflectionQuote = quote
        }
        if (currentState == State.EXPANDED) {
            renderCarouselPage(currentCarouselPage)
        }
    }

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
                pillContainer.setPadding(dpToPx(4), dpToPx(4), dpToPx(4), dpToPx(4))
                headerRow.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.GONE
                secondaryTextView.visibility = View.GONE
                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.GONE
            }

            State.APP_DETECTED -> {
                targetW = dpToPx(210)
                targetH = dpToPx(36)
                pillContainer.setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
                headerRow.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.VISIBLE

                primaryTextView.text = currentAppName
                secondaryTextView.text = "· ${formatDuration(currentTodayMs)}"

                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.GONE
                autoCollapseDelay = 4500L
            }

            State.USAGE_DISPLAY -> {
                targetW = dpToPx(230)
                targetH = dpToPx(36)
                pillContainer.setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
                headerRow.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.VISIBLE

                primaryTextView.text = currentAppName
                secondaryTextView.text = "${formatDuration(currentTodayMs)} today"

                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.GONE
                autoCollapseDelay = 5000L
            }

            State.COLLAPSED -> {
                targetW = dpToPx(82)
                targetH = dpToPx(28)
                pillContainer.setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(4))
                headerRow.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.GONE

                primaryTextView.text = formatDuration(currentTodayMs)
                primaryTextView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)

                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.GONE
            }

            State.EXPANDED -> {
                targetW = dpToPx(315)
                targetH = dpToPx(182)
                pillContainer.setPadding(dpToPx(16), dpToPx(12), dpToPx(16), dpToPx(10))
                headerRow.visibility = View.VISIBLE
                appIconView.visibility = View.GONE
                primaryTextView.visibility = View.VISIBLE
                secondaryTextView.visibility = View.VISIBLE

                primaryTextView.text = currentAppName
                primaryTextView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
                secondaryTextView.text = "Today: ${formatDuration(currentTodayMs)}"

                specialContentLayout.visibility = View.GONE
                carouselContainer.visibility = View.VISIBLE
                renderCarouselPage(currentCarouselPage)
            }

            State.CONTEXTUAL_NUDGE -> {
                targetW = dpToPx(300)
                targetH = dpToPx(155)
                pillContainer.setPadding(dpToPx(14), dpToPx(10), dpToPx(14), dpToPx(10))
                headerRow.visibility = View.VISIBLE
                primaryTextView.text = "$currentAppName · ${formatDuration(currentSessionMs)}"
                secondaryTextView.visibility = View.GONE

                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.VISIBLE
                val taskTitle = (extraPayload["taskTitle"] as? String) ?: "Your planned focus"
                setupNudgeContent(taskTitle)
                autoCollapseDelay = 12000L
            }

            State.ASSISTANT_LISTENING -> {
                targetW = dpToPx(220)
                targetH = dpToPx(38)
                pillContainer.setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
                headerRow.visibility = View.VISIBLE
                primaryTextView.text = "I'm listening"
                secondaryTextView.text = "● ● ●"
                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.GONE
            }

            State.ASSISTANT_PROCESSING -> {
                targetW = dpToPx(190)
                targetH = dpToPx(38)
                pillContainer.setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
                headerRow.visibility = View.VISIBLE
                primaryTextView.text = "Reflecting"
                secondaryTextView.text = "✦"
                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.GONE
            }

            State.ASSISTANT_RESPONDING -> {
                targetW = dpToPx(280)
                targetH = dpToPx(115)
                pillContainer.setPadding(dpToPx(14), dpToPx(10), dpToPx(14), dpToPx(10))
                headerRow.visibility = View.VISIBLE
                primaryTextView.text = "Mindful Assistant"
                secondaryTextView.visibility = View.GONE
                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.VISIBLE

                val message = (extraPayload["message"] as? String) ?: "Task captured."
                setupAssistantResponseContent(message)
                autoCollapseDelay = 6000L
            }

            State.CHECK_IN -> {
                targetW = dpToPx(280)
                targetH = dpToPx(135)
                pillContainer.setPadding(dpToPx(14), dpToPx(10), dpToPx(14), dpToPx(10))
                headerRow.visibility = View.VISIBLE
                primaryTextView.text = "Mindful Check-in"
                secondaryTextView.visibility = View.GONE
                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.VISIBLE

                setupCheckInContent()
                autoCollapseDelay = 15000L
            }

            State.REFLECTION -> {
                targetW = dpToPx(290)
                targetH = dpToPx(120)
                pillContainer.setPadding(dpToPx(14), dpToPx(10), dpToPx(14), dpToPx(10))
                headerRow.visibility = View.VISIBLE
                primaryTextView.text = "Pause & Reflect"
                secondaryTextView.visibility = View.GONE
                carouselContainer.visibility = View.GONE
                specialContentLayout.visibility = View.VISIBLE

                val quote = (extraPayload["quote"] as? String) ?: reflectionQuote
                setupReflectionContent(quote)
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

        OverlayEventBridge.sendEvent(
            "notch_state_changed",
            mapOf("state" to newState.name, "packageName" to currentPackage)
        )
    }

    private fun renderCarouselPage(page: Int) {
        pageUsageLayout.visibility = if (page == 0) View.VISIBLE else View.GONE
        pageTasksLayout.visibility = if (page == 1) View.VISIBLE else View.GONE
        pageReflectionLayout.visibility = if (page == 2) View.VISIBLE else View.GONE

        updateDotIndicators(page)

        when (page) {
            0 -> {
                // Page 0: Usage
                usageSessionTextView.text = "Current session: ${formatDuration(currentSessionMs)}"
                setupUsageButtons()
                swipeHintTextView.text = "Swipe left for tasks & reflection →"
            }
            1 -> {
                // Page 1: Tasks
                setupTasksContent()
                swipeHintTextView.text = "← Usage | Swipe left for reflection →"
            }
            2 -> {
                // Page 2: Reflection (entirely enclosed in notch)
                reflectionQuoteTextView.text = "“$reflectionQuote”"
                swipeHintTextView.text = "← Tasks | Tap notch to collapse"
            }
        }
    }

    private fun setupUsageButtons() {
        usageActionsLayout.removeAllViews()

        val intentionalBtn = createPillButton("Intentional", "#2D4A3E") {
            onInteraction("classify_session", mapOf("package" to currentPackage, "intentional" to true))
            transitionTo(State.COLLAPSED)
        }
        val unintentionalBtn = createPillButton("Unintentional", "#4A2D30") {
            onInteraction("classify_session", mapOf("package" to currentPackage, "intentional" to false))
            transitionTo(State.COLLAPSED)
        }
        val dismissBtn = createPillButton("Dismiss", "#1E2B18") {
            transitionTo(State.COLLAPSED)
        }

        usageActionsLayout.addView(intentionalBtn)
        usageActionsLayout.addView(unintentionalBtn)
        usageActionsLayout.addView(dismissBtn)
    }

    private fun setupTasksContent() {
        tasksItemsLayout.removeAllViews()

        if (activeTasks.isEmpty()) {
            val emptyTv = TextView(context).apply {
                text = "No open priorities today.\nStay mindful of your presence."
                setTextColor(Color.parseColor("#B0BEA8"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
                gravity = Gravity.CENTER
                setPadding(dpToPx(8), dpToPx(8), dpToPx(8), dpToPx(8))
            }
            tasksItemsLayout.addView(emptyTv)
        } else {
            val count = activeTasks.size.coerceAtMost(3)
            for (i in 0 until count) {
                val taskTitle = activeTasks[i]
                val taskRow = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(dpToPx(14), dpToPx(3), dpToPx(14), dpToPx(3))

                    val checkIcon = TextView(context).apply {
                        text = "○ "
                        setTextColor(Color.parseColor("#9FE870"))
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                    }
                    val label = TextView(context).apply {
                        text = taskTitle
                        setTextColor(Color.parseColor("#FAF9F6"))
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                        maxLines = 1
                    }
                    addView(checkIcon)
                    addView(label)
                }
                tasksItemsLayout.addView(taskRow)
            }
        }
    }

    private fun setupNudgeContent(taskTitle: String) {
        specialContentLayout.removeAllViews()

        val promptText = TextView(context).apply {
            text = "You planned to work on:\n\"$taskTitle\"\nBack to it?"
            setTextColor(Color.parseColor("#FAF9F6"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(6))
        }
        specialContentLayout.addView(promptText)

        val btnRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        val backBtn = createPillButton("Back to Task", "#2D4A3E") {
            onInteraction("nudge_action_return", mapOf("package" to currentPackage))
            transitionTo(State.COLLAPSED)
        }
        val stayBtn = createPillButton("Stay 5m", "#1E2B18") {
            onInteraction("nudge_action_snooze", mapOf("package" to currentPackage))
            transitionTo(State.COLLAPSED)
        }
        btnRow.addView(backBtn)
        btnRow.addView(stayBtn)
        specialContentLayout.addView(btnRow)
    }

    private fun setupCheckInContent() {
        specialContentLayout.removeAllViews()

        val question = TextView(context).apply {
            text = "How does your attention feel right now?"
            setTextColor(Color.parseColor("#FAF9F6"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding(0, dpToPx(4), 0, dpToPx(6))
        }
        specialContentLayout.addView(question)

        val btnRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
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
        btnRow.addView(moodGood)
        btnRow.addView(moodNeutral)
        btnRow.addView(moodDistracted)
        specialContentLayout.addView(btnRow)
    }

    private fun setupReflectionContent(quote: String) {
        specialContentLayout.removeAllViews()
        val quoteView = TextView(context).apply {
            text = "“$quote”"
            setTextColor(Color.parseColor("#FAF9F6"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.create("sans-serif", Typeface.ITALIC)
            gravity = Gravity.CENTER
            setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
        }
        specialContentLayout.addView(quoteView)
    }

    private fun setupAssistantResponseContent(message: String) {
        specialContentLayout.removeAllViews()
        val respView = TextView(context).apply {
            text = message
            setTextColor(Color.parseColor("#FAF9F6"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setPadding(dpToPx(10), dpToPx(4), dpToPx(10), dpToPx(6))
        }
        specialContentLayout.addView(respView)
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
                val radius = (currH / 2f).coerceAtMost(dpToPx(24).toFloat())
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

    private fun createPillButton(text: String, bgColor: String, onClick: () -> Unit): Button {
        return Button(context).apply {
            this.text = text
            setTextColor(Color.parseColor("#FAF9F6"))
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
