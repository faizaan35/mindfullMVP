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
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
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
        isClickable = true
        isFocusable = false
    }

    // Morphing Pill Container - ENCLOSES ALL NOTCH CONTENT COMPLETELY
    private val pillContainer = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        isClickable = true
        isFocusable = false
    }

    // Top Header Row (always top of pill)
    private val headerRow = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
        isClickable = false
        isFocusable = false
    }
    private val appIconView = ImageView(context).apply {
        isClickable = false
        isFocusable = false
    }
    private val primaryTextView = TextView(context).apply {
        isClickable = false
        isFocusable = false
    }
    private val secondaryTextView = TextView(context).apply {
        isClickable = false
        isFocusable = false
    }

    // Expanded Multi-Page Carousel Container (inside pill)
    private val carouselContainer = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        visibility = View.GONE
        isClickable = false
        isFocusable = false
    }

    // Page 0: Usage Details
    private val pageUsageLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        isClickable = false
        isFocusable = false
    }
    private val usageSessionTextView = TextView(context).apply {
        isClickable = false
        isFocusable = false
    }
    private val usageActionsLayout = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
    }

    // Page 1: Tasks
    private val pageTasksLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        isClickable = false
        isFocusable = false
    }
    private val tasksHeaderView = TextView(context).apply {
        isClickable = false
        isFocusable = false
    }
    private val tasksItemsLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.START
        isClickable = false
        isFocusable = false
    }

    // Page 2: Mindfulness & Reflection
    private val pageReflectionLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        isClickable = false
        isFocusable = false
    }
    private val reflectionHeaderView = TextView(context).apply {
        isClickable = false
        isFocusable = false
    }
    private val reflectionQuoteTextView = TextView(context).apply {
        isClickable = false
        isFocusable = false
    }

    // Bottom Navigation Dots & Hint (inside pill)
    private val footerLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        isClickable = false
        isFocusable = false
    }
    private val dotsLayout = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
        isClickable = false
        isFocusable = false
    }
    private val dotViews = ArrayList<View>()
    private val swipeHintTextView = TextView(context).apply {
        isClickable = false
        isFocusable = false
    }

    // Special Event Layout (for Nudge, Check-in, Assistant)
    private val specialContentLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        visibility = View.GONE
    }

    // ORIGINAL NOTCH VISUAL IDENTITY: Matte Obsidian & Warm Alabaster Outline
    private val backgroundDrawable = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        setColor(Color.parseColor("#121214")) // Original Matte Obsidian Dark
        setStroke(dpToPx(1), Color.parseColor("#2C2A28")) // Original Warm Outline
        cornerRadius = dpToPx(24).toFloat()
    }

    private var currentTargetWidth = dpToPx(96)
    private var currentTargetHeight = dpToPx(30)

    // Touch-optimized LayoutParams with exact pixel dimensions to avoid untrusted touches
    private val layoutParams = WindowManager.LayoutParams(
        currentTargetWidth,
        currentTargetHeight,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        y = dpToPx(38) // Positioned directly below the 110px status bar to guarantee 100% touch interception
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    // Current app context
    private var currentPackage: String = ""
    private var currentAppName: String = "Mindful"
    private var currentSessionMs: Long = 0L
    private var currentTodayMs: Long = 0L

    // Carousel state: 0 = Usage, 1 = Tasks, 2 = Reflection
    private var currentCarouselPage = 0
    private var activeTasks: List<String> = emptyList()
    private val reflectionQuote: String = "The attention you give something is the life you give it."

    // Gesture tracking variables using absolute screen coordinates
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
        appIconView.layoutParams = LinearLayout.LayoutParams(dpToPx(15), dpToPx(15)).apply {
            marginEnd = dpToPx(6)
        }
        appIconView.visibility = View.GONE

        // Primary Text - Original Warm Alabaster
        primaryTextView.apply {
            setTextColor(Color.parseColor("#F5F2EB"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            maxLines = 1
            gravity = Gravity.CENTER
        }

        // Secondary Text - Original Warm Oat / Stone
        secondaryTextView.apply {
            setTextColor(Color.parseColor("#9E988F"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            setPadding(dpToPx(5), 0, 0, 0)
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
            setTextColor(Color.parseColor("#C4BEB5"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(6), 0, dpToPx(8))
        }
        pageUsageLayout.addView(usageSessionTextView)
        pageUsageLayout.addView(usageActionsLayout)

        // 2. Page Tasks
        tasksHeaderView.apply {
            text = "TODAY'S PRIORITIES"
            setTextColor(Color.parseColor("#9E988F"))
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
            setTextColor(Color.parseColor("#9E988F"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(4), 0, dpToPx(4))
        }
        reflectionQuoteTextView.apply {
            setTextColor(Color.parseColor("#DED9CE"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.create("sans-serif", Typeface.ITALIC)
            gravity = Gravity.CENTER
            maxLines = 3
            setPadding(dpToPx(14), dpToPx(4), dpToPx(14), dpToPx(6))
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
            setTextColor(Color.parseColor("#7A7670"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 9.5f)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(4), 0, dpToPx(2))
        }
        footerLayout.addView(dotsLayout)
        footerLayout.addView(swipeHintTextView)
        carouselContainer.addView(footerLayout)

        pillContainer.addView(carouselContainer)
        pillContainer.addView(specialContentLayout)

        // ROOT VIEW matches dimensions of layoutParams
        rootView.addView(
            pillContainer,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )
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
                    setColor(if (i == 0) Color.parseColor("#F5F2EB") else Color.parseColor("#3C3A38"))
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
                bg.setColor(Color.parseColor("#F5F2EB")) // Active Warm Alabaster
            } else {
                bg.setColor(Color.parseColor("#3C3A38")) // Inactive Warm Slate
            }
        }
    }

    private fun setupTouchGestures() {
        val unifiedTouchListener = View.OnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    touchStartX = event.rawX
                    touchStartY = event.rawY
                    touchStartTime = System.currentTimeMillis()
                    true // Must claim touch stream from WindowManager
                }

                MotionEvent.ACTION_MOVE -> {
                    true
                }

                MotionEvent.ACTION_UP -> {
                    val deltaX = event.rawX - touchStartX
                    val deltaY = event.rawY - touchStartY
                    val duration = System.currentTimeMillis() - touchStartTime

                    val isTap = abs(deltaX) < dpToPx(18) && abs(deltaY) < dpToPx(18) && duration < 600

                    if (isTap) {
                        onPillTapped()
                    } else if (currentState == State.EXPANDED) {
                        if (abs(deltaX) > abs(deltaY) && abs(deltaX) > dpToPx(20)) {
                            if (deltaX < 0) {
                                // Swipe LEFT -> advance page
                                if (currentCarouselPage < 2) {
                                    currentCarouselPage++
                                    renderCarouselPage(currentCarouselPage)
                                }
                            } else {
                                // Swipe RIGHT -> go back
                                if (currentCarouselPage > 0) {
                                    currentCarouselPage--
                                    renderCarouselPage(currentCarouselPage)
                                }
                            }
                        } else if (deltaY < -dpToPx(20)) {
                            // Swipe UP -> collapse
                            transitionTo(State.COLLAPSED)
                        }
                    }
                    true
                }

                MotionEvent.ACTION_CANCEL -> {
                    true
                }

                else -> true
            }
        }

        pillContainer.setOnTouchListener(unifiedTouchListener)
        rootView.setOnTouchListener(unifiedTouchListener)
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
                swipeHintTextView.text = "Swipe left for priorities & quote →"
            }
            1 -> {
                // Page 1: Tasks
                setupTasksContent()
                swipeHintTextView.text = "← Usage | Swipe left for reflection →"
            }
            2 -> {
                // Page 2: Reflection (enclosed completely inside notch)
                reflectionQuoteTextView.text = "“$reflectionQuote”"
                swipeHintTextView.text = "← Priorities | Tap notch to collapse"
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
        val dismissBtn = createPillButton("Dismiss", "#252422") {
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
                setTextColor(Color.parseColor("#9E988F"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
                gravity = Gravity.CENTER
                setPadding(dpToPx(8), dpToPx(8), dpToPx(8), dpToPx(8))
                isClickable = false
                isFocusable = false
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
                    isClickable = false
                    isFocusable = false

                    val checkIcon = TextView(context).apply {
                        text = "○ "
                        setTextColor(Color.parseColor("#9E988F"))
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                        isClickable = false
                        isFocusable = false
                    }
                    val label = TextView(context).apply {
                        text = taskTitle
                        setTextColor(Color.parseColor("#F5F2EB"))
                        setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                        maxLines = 1
                        isClickable = false
                        isFocusable = false
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
            setTextColor(Color.parseColor("#F5F2EB"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(6))
            isClickable = false
            isFocusable = false
        }
        specialContentLayout.addView(promptText)

        val btnRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        val backBtn = createPillButton("Back to Task", "#3B5342") {
            onInteraction("nudge_action_return", mapOf("package" to currentPackage))
            transitionTo(State.COLLAPSED)
        }
        val stayBtn = createPillButton("Stay 5m", "#262524") {
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
            setTextColor(Color.parseColor("#F5F2EB"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding(0, dpToPx(4), 0, dpToPx(6))
            isClickable = false
            isFocusable = false
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
            setTextColor(Color.parseColor("#DED9CE"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.create("sans-serif", Typeface.ITALIC)
            gravity = Gravity.CENTER
            setPadding(dpToPx(14), dpToPx(6), dpToPx(14), dpToPx(6))
            isClickable = false
            isFocusable = false
        }
        specialContentLayout.addView(quoteView)
    }

    private fun setupAssistantResponseContent(message: String) {
        specialContentLayout.removeAllViews()
        val respView = TextView(context).apply {
            text = message
            setTextColor(Color.parseColor("#F5F2EB"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setPadding(dpToPx(10), dpToPx(4), dpToPx(10), dpToPx(6))
            isClickable = false
            isFocusable = false
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
            duration = 300L
            interpolator = DecelerateInterpolator(1.8f)
            addUpdateListener { anim ->
                val fraction = anim.animatedFraction
                val currW = (startW + (targetWidth - startW) * fraction).toInt()
                val currH = (startH + (targetHeight - startH) * fraction).toInt()

                // Crucial: update WindowManager.LayoutParams width/height directly so the InputChannel touch bounds match the pill
                layoutParams.width = currW
                layoutParams.height = currH

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
