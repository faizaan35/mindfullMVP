# AGENTS.md

# Mindfulness Companion — Engineering & Product Specification

> **Codename:** TBD  
> **Platform:** Android first  
> **Framework:** Flutter / Dart  
> **Development Environment:** Android Studio / VS Code  
> **Primary AI Coding Agent:** AntiGravity  
> **Status:** Greenfield project  
> **Current Target:** Phase 1 only

---

# 1. PRODUCT VISION

Build an Android-first mindfulness and attention-awareness companion.

The application monitors how the user spends time on their phone and provides a persistent, minimal, highly polished interface that gently brings the user's attention back to what they intended to do.

The defining interface is a **Dynamic Notch / Dynamic Island-inspired floating pill**.

The pill exists above other applications and changes shape and content depending on context.

It should feel like a single intelligent object that can:

- show current app usage
- show today's usage
- display contextual mindfulness information
- expand into richer information
- eventually interact with tasks and habits
- eventually act as an AI assistant
- eventually provide check-ins and reflections

The product is NOT intended to be a conventional screen-time blocker.

The philosophy is:

> **Make the user aware of their attention rather than controlling their attention.**

The application should avoid being judgmental.

Do not repeatedly tell users they are "wasting time."

Prefer neutral concepts such as:

- Time spent
- Attention spent
- Today's usage
- Session duration
- Intentional / unintentional
- Daily intention
- Focus
- Reflection

---

# 2. CORE PRODUCT CONCEPT

The application consists of two primary experiences:

## A. The Main App

The normal Flutter application where users can:

- view statistics
- configure tracking
- view usage history
- eventually manage tasks/habits
- eventually configure AI behavior
- configure notification/check-in behavior

## B. The Floating Attention Layer

A floating overlay that appears above other Android applications.

This is the application's defining feature.

The overlay should resemble a small pill near the top-center of the screen.

Example:

```text
       ┌──────────────────────────┐
       │   Instagram · 18m today  │
       └──────────────────────────┘
```

The pill can:

1. remain dormant
2. appear briefly when an app becomes active
3. show usage information
4. expand
5. collapse
6. eventually become an assistant interface
7. eventually display tasks, reminders and check-ins

The UI should always feel like the **same object morphing between states**.

Do NOT implement these states as disconnected screens.

---

# 3. PRODUCT PRINCIPLES

These principles are mandatory.

## 3.1 Mindfulness over restriction

Do not build a traditional app blocker.

Do not aggressively interrupt the user.

The application should create awareness.

Bad:

> "STOP WASTING YOUR TIME."

Good:

> "You've spent 24m on Instagram today."

Better:

> "24m on Instagram. Your next task is still waiting."

---

## 3.2 Context over generic notifications

The application should eventually understand:

- what app is being used
- how long it has been used
- what the user intended to accomplish
- what tasks remain
- time of day
- previous interactions

A reminder should be contextual.

Example:

The user has a task:

> Finish DB assignment

They open Instagram.

After a configured period:

```text
Instagram · 24m

You planned to finish
your DB assignment.

Back to it?
```

This should feel like a gentle nudge rather than an alarm.

---

## 3.3 The Dynamic Notch is the USP

The overlay is NOT decorative.

It is the primary interaction surface.

The application should be designed around it.

Do not build a generic productivity app and add an overlay later.

The architecture must allow the overlay to evolve into the primary interface.

---

## 3.4 Animation quality is critical

The floating interface must feel premium.

Prioritize:

- smooth expansion
- smooth contraction
- spring animations
- shared geometry
- opacity transitions
- scale transitions
- content crossfades
- minimal layout jumps
- natural timing
- interruptible animations
- consistent corner radius
- consistent visual language

Avoid:

- abrupt popups
- standard Android dialogs
- ugly Toasts
- arbitrary fades
- multiple unrelated widgets appearing independently
- excessive animations
- animation for the sake of animation

The desired feeling is:

> **One small object intelligently transforming into different states.**

---

# 4. IMPORTANT SCOPE RULE

## DO NOT IMPLEMENT ALL FOUR PHASES AT ONCE.

The project is intentionally divided into four phases.

Only the currently active phase should be implemented.

Future phases should influence architecture where appropriate, but they must NOT be prematurely implemented.

Current target:

# PHASE 1 — CORE ATTENTION TRACKING + DYNAMIC NOTCH

Do not implement Phase 2, 3 or 4 unless explicitly instructed.

---

# 5. TECHNOLOGY STACK

## Mobile

Flutter

Dart

Target:

Android first.

iOS is NOT part of the initial implementation.

---

## Android Native Layer

Flutter cannot independently provide all required functionality.

Use native Android/Kotlin integration where necessary.

Potential Android APIs/components include:

- UsageStatsManager
- PACKAGE_USAGE_STATS
- SYSTEM_ALERT_WINDOW
- foreground services where required
- Android notifications
- MethodChannel
- EventChannel where appropriate
- Android lifecycle APIs

Native Android code should be isolated from Flutter UI logic.

Do not scatter Android-specific logic throughout the Flutter application.

---

## Local Storage

Use a local database suitable for Flutter.

Preferred initial option:

- SQLite / Drift

Alternative:

- Hive

Choose one and use it consistently.

Do NOT introduce multiple local databases without a clear reason.

---

## State Management

Choose a lightweight, maintainable approach.

Preferred:

- Riverpod

Do not introduce large state-management abstractions unnecessarily.

---

## Architecture

Use a clean separation between:

```text
Presentation
    ↓
Application / State
    ↓
Domain
    ↓
Data
    ↓
Platform Services
```

Android-specific functionality should sit behind interfaces/services.

---

# 6. HIGH-LEVEL ARCHITECTURE

```text
                    ┌────────────────────┐
                    │    Flutter App     │
                    │                    │
                    │ Dashboard          │
                    │ Statistics         │
                    │ Settings           │
                    └─────────┬──────────┘
                              │
                              │
                    ┌─────────▼──────────┐
                    │ Application Layer  │
                    │                    │
                    │ Usage Repository   │
                    │ Tracking Service   │
                    │ Overlay Controller │
                    └─────────┬──────────┘
                              │
             ┌────────────────┴────────────────┐
             │                                 │
   ┌─────────▼─────────┐             ┌────────▼─────────┐
   │ Android Platform  │             │ Local Database   │
   │                   │             │                  │
   │ UsageStatsManager │             │ Usage Sessions   │
   │ Overlay Service   │             │ Daily Totals     │
   │ Permissions       │             │ App Metadata     │
   └───────────────────┘             └──────────────────┘
```

---

# 7. PROJECT STRUCTURE

Use a structure similar to:

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── extensions/
│   ├── utils/
│   └── errors/
│
├── features/
│   ├── usage/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   │
│   ├── overlay/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   │
│   ├── dashboard/
│   └── settings/
│
└── platform/
    └── android/
        ├── usage_stats/
        ├── overlay/
        └── permissions/
```

Android:

```text
android/
└── app/
    └── src/
        └── main/
            ├── kotlin/
            │   └── ...
            └── AndroidManifest.xml
```

Keep platform-specific code isolated.

---

# 8. PHASE 1 — CORE MVP

# Objective

Build a working Android mindfulness tracker with:

1. application usage tracking
2. daily usage statistics
3. floating Dynamic Notch
4. contextual app usage display
5. polished animations
6. basic settings
7. persistent local data

Nothing beyond this is required for Phase 1.

---

# 9. PHASE 1 — USAGE TRACKING

The application must detect which application is currently being used.

Use Android's UsageStats functionality.

The system should be able to determine:

```text
Current Application
Session Start
Session End
Session Duration
Daily Total
```

Example:

```text
Instagram
09:42 → 10:03
21 minutes
```

---

# 10. SUPPORTED APPLICATIONS

The system should NOT hard-code only Instagram and YouTube.

Architecture must support arbitrary installed applications.

Create a generic application model.

Example:

```dart
class TrackedApp {
  final String packageName;
  final String displayName;
  final String? icon;
}
```

Examples:

```text
com.instagram.android
com.google.android.youtube
com.reddit.frontpage
com.google.android.apps.chrome
```

The user should eventually be able to choose which applications are tracked.

---

# 11. APP SESSION MODEL

Represent individual usage sessions.

Example:

```dart
class AppSession {
  final String packageName;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
}
```

Do not store only aggregated daily totals.

Individual sessions will be useful later for:

- usage analysis
- intentional/unintentional classification
- AI context
- behavioral patterns
- charts
- future Reel/Short detection

---

# 12. DAILY AGGREGATION

The system should calculate:

```text
Today's total screen time
Per-app total
Number of sessions
Longest session
First session
Last session
```

Example:

```text
Today

Instagram
1h 24m
8 sessions

YouTube
52m
4 sessions

Chrome
38m
12 sessions
```

---

# 13. SESSION DETECTION

The system should correctly handle:

- opening an app
- switching apps
- returning to an app
- locking the phone
- unlocking the phone
- device reboot
- application termination
- midnight/day rollover

Do not assume the application itself is always running in the foreground.

Usage tracking must survive the Flutter application being closed.

---

# 14. PERMISSIONS

The application should detect whether required Android permissions have been granted.

At minimum, investigate and implement the appropriate handling for:

### Usage Access

Required for UsageStats.

### Overlay Permission

Required for displaying the floating pill above other applications.

The user should be guided through permission setup.

Do not silently fail.

If permissions are missing, show a clear explanation.

Example:

```text
Usage access required

Mindfulness needs access to app usage
information so it can show you how
you spend time on your phone.

[Open Settings]
```

---

# 15. DYNAMIC NOTCH

The Dynamic Notch is the central feature.

It should be implemented as an Android overlay.

The Flutter application controls the state/content where practical, while the Android platform layer manages the actual overlay window.

The overlay must:

- remain above supported applications
- appear near the top-center
- avoid interfering with touch input when collapsed
- handle Android navigation/status bar differences
- account for different screen sizes
- account for different aspect ratios
- behave correctly across portrait orientations

---

# 16. NOTCH STATES

Implement a state machine.

Example:

```text
DORMANT
   ↓
APP_DETECTED
   ↓
USAGE_DISPLAY
   ↓
COLLAPSED
   ↓
EXPANDED
   ↓
COLLAPSED
```

Future states:

```text
ASSISTANT
TASK
CHECK_IN
REFLECTION
```

These future states should NOT be implemented in Phase 1.

But the architecture should allow them.

---

# 17. STATE DEFINITIONS

## DORMANT

The overlay is invisible or represented by a tiny minimal indicator.

---

## APP_DETECTED

Triggered when the user enters a tracked application.

Example:

```text
┌─────────────────────────────┐
│      Instagram · 18m        │
└─────────────────────────────┘
```

Display for a short configurable period.

---

## USAGE_DISPLAY

Shows:

```text
Instagram
18m today
```

Potential secondary information:

```text
Session: 7m
Today: 18m
```

---

## COLLAPSED

The overlay becomes a small pill/dot.

It should not permanently occupy a large portion of the screen.

---

## EXPANDED

Phase 1 may implement a manually triggered expansion.

Example:

```text
╭──────────────────────────────╮
│                              │
│          Instagram           │
│                              │
│          18m today           │
│                              │
│          Session 7m          │
│                              │
╰──────────────────────────────╯
```

---

# 18. ANIMATION REQUIREMENTS

Animations must be designed as transitions between states.

Do NOT simply remove one widget and create another.

Preferred techniques:

- AnimatedContainer
- TweenAnimationBuilder
- custom AnimationController
- Hero-like geometry transitions
- scale
- size
- opacity
- border radius
- blur
- clipping

The visual transformation should resemble:

```text
small pill
     ↓
wide pill
     ↓
large rounded container
     ↓
content appears
     ↓
collapse
     ↓
small pill
```

Timing should feel natural.

Avoid excessive bounce.

Avoid cartoon-like animations.

The product aesthetic should be:

- premium
- calm
- minimal
- futuristic
- warm
- intentional

---

# 19. UI DESIGN LANGUAGE

The design should NOT look like generic AI-generated SaaS.

Avoid:

- random gradients
- excessive glassmorphism
- dark-mode-only interfaces
- neon purple AI aesthetics
- generic dashboard cards
- meaningless decorative text
- fake statistics
- excessive rounded rectangles
- arbitrary icons everywhere

Preferred aesthetic:

- warm
- refined
- minimal
- tactile
- calm
- intentional
- high-quality typography
- subtle depth
- restrained color palette

Dark mode may be supported eventually, but the default design should not depend on a dark neon aesthetic.

---

# 20. MAIN DASHBOARD

Phase 1 dashboard should provide useful information without becoming a giant analytics application.

Example:

```text
GOOD EVENING

Your attention today

3h 42m

────────────────────

Instagram     1h 24m
YouTube        52m
Chrome         38m
WhatsApp       27m

────────────────────

8 sessions
Longest session: 31m
```

Potential sections:

- total usage
- top applications
- number of sessions
- longest session
- today's timeline

---

# 21. STATISTICS

Implement basic statistics.

Required:

### Daily

- total usage
- usage per app
- sessions per app
- longest session

### History

At minimum:

- last 7 days

Example:

```text
Mon  3h 12m
Tue  4h 02m
Wed  3h 41m
Thu  5h 18m
Fri  3h 52m
Sat  4h 31m
Sun  3h 42m
```

Charts should be simple.

Do not build an enormous analytics dashboard.

---

# 22. SETTINGS

Phase 1 settings:

- Enable/disable floating notch
- Choose tracked applications
- Notch display duration
- Enable/disable usage notifications
- Overlay permission status
- Usage permission status

Future settings should not be implemented yet.

---

# 23. PHASE 1 — WHAT NOT TO BUILD

Do NOT implement:

- AI chatbot
- voice assistant
- wake word detection
- task management
- habit tracking
- journaling
- daily check-ins
- quote system
- Reel counting
- YouTube Shorts counting
- AI recommendations
- cloud sync
- accounts
- social features
- backend server
- subscription system

These belong to later phases.

---

# 24. PHASE 1 ACCEPTANCE CRITERIA

Phase 1 is complete only when:

### Usage

- [ ] Android usage access works
- [ ] Current foreground app can be detected
- [ ] Usage sessions are recorded
- [ ] Daily totals are calculated
- [ ] App-specific totals are calculated
- [ ] Data persists after restart
- [ ] Midnight rollover works

### Overlay

- [ ] Overlay permission flow works
- [ ] Dynamic Notch appears above supported apps
- [ ] Correct application name is displayed
- [ ] Today's usage is displayed
- [ ] Overlay collapses correctly
- [ ] Overlay does not permanently obstruct the user
- [ ] Overlay survives Flutter app closure where required

### UI

- [ ] Dashboard works
- [ ] Statistics work
- [ ] Settings work
- [ ] Animations are smooth
- [ ] No obvious layout issues on different Android screen sizes

### Reliability

- [ ] No crashes during normal app switching
- [ ] No runaway background service
- [ ] No excessive battery consumption caused by aggressive polling
- [ ] No duplicate usage sessions
- [ ] No duplicate overlays

---

# 25. PHASE 2 — MINDFULNESS + INTENT

## Objective

Turn the application from a usage tracker into an actual mindfulness companion.

Phase 2 introduces:

- daily intentions
- tasks
- habits
- contextual reminders
- mindfulness nudges
- intentional/unintentional usage

---

# 26. DAILY TASKS

Users can define what they want to accomplish today.

Example:

```text
TODAY

☐ Finish DB assignment
☐ Go to gym
☐ Revise calculus
☐ Read 20 pages
```

Tasks should support:

- title
- optional description
- optional deadline
- completion state
- creation time
- completion time

---

# 27. INTENTION SETTING

The user should be able to say:

> "What do I want to achieve today?"

The app can eventually accept natural language.

For Phase 2, a simple manual interface is sufficient.

Example:

```text
Today's intention

What matters today?

[ Finish my DB project       ]

[ Save ]
```

---

# 28. CONTEXTUAL NUDGES

The application can connect usage with intentions.

Example:

```text
User task:
Finish DB assignment

Current app:
Instagram

Current session:
24 minutes
```

The notch can display:

```text
Instagram · 24m

You planned to finish
your DB assignment.

Back to it?
```

Important:

Do not make the application aggressive.

The user should be able to configure:

- reminder threshold
- cooldown
- tracked applications
- quiet hours
- whether reminders are enabled

---

# 29. INTENTIONAL VS UNINTENTIONAL TIME

Do not automatically decide that social media is "bad."

Allow the user to classify sessions.

For example:

```text
Instagram · 18m

What was this?

○ Intentional
○ Unintentional
```

This data can later produce insights.

Example:

```text
This week

Intentional: 61%
Unintentional: 39%
```

Do not moralize the results.

---

# 30. HABITS

Phase 2 may introduce simple habits.

Examples:

```text
Morning walk
Gym
Read
Meditate
Study
Sleep before 12
```

Track:

- completion
- streak
- frequency

Do not turn the application into a generic habit tracker.

Habits must remain connected to the attention/mindfulness concept.

---

# 31. PHASE 2 ACCEPTANCE CRITERIA

- [ ] Daily tasks work
- [ ] Tasks persist
- [ ] Tasks can be completed
- [ ] Tasks can have deadlines
- [ ] User can configure reminders
- [ ] Contextual reminders work
- [ ] Cooldowns prevent spam
- [ ] Habits work
- [ ] Intentional/unintentional classification works
- [ ] Dynamic Notch can display contextual task information

---

# 32. PHASE 3 — AI COMPANION

## Objective

Turn the mindfulness layer into an AI-powered personal attention assistant.

AI should not replace deterministic application logic.

Use AI where natural language understanding is useful.

---

# 33. AI RESPONSIBILITIES

The AI may:

- turn natural language into tasks
- organize daily goals
- interpret vague intentions
- summarize the user's day
- suggest reflection prompts
- understand voice commands
- help configure habits
- provide contextual suggestions

The AI should NOT be responsible for:

- calculating screen time
- detecting current applications
- scheduling exact timers
- enforcing cooldowns
- storing authoritative task state
- permission management

Those should remain deterministic.

---

# 34. AI TASK CREATION

Example user input:

> "I need to finish my DB assignment before 10, go to the gym around 7 and revise calculus for an hour."

AI should produce structured data:

```json
{
  "tasks": [
    {
      "title": "Finish DB assignment",
      "deadline": "22:00"
    },
    {
      "title": "Go to the gym",
      "time": "19:00"
    },
    {
      "title": "Revise calculus",
      "durationMinutes": 60
    }
  ]
}
```

The application validates the result before saving it.

Never directly execute arbitrary AI-generated actions.

---

# 35. VOICE ASSISTANT

Eventually support an interaction similar to:

```text
User:
"Hey Mindful..."

             ↓

Dynamic Notch expands

             ↓

"I'm listening."

             ↓

User:
"I want to finish my project today."

             ↓

AI parses intent

             ↓

"Added: Finish project"
```

Do not build always-listening wake-word detection until explicitly required.

Start with:

- tap-to-listen
- notification action
- explicit activation

Wake-word detection can be evaluated later.

---

# 36. AI NOTCH STATES

Phase 3 introduces:

```text
ASSISTANT_IDLE
ASSISTANT_LISTENING
ASSISTANT_PROCESSING
ASSISTANT_RESPONDING
```

Visual example:

```text
╭──────────────────────────╮
│                          │
│       I'm listening      │
│          ● ● ●           │
│                          │
╰──────────────────────────╯
```

Then:

```text
╭──────────────────────────╮
│                          │
│       Added task         │
│                          │
│       Finish project     │
│                          │
╰──────────────────────────╯
```

The transition must reuse the same Dynamic Notch animation system.

---

# 37. AI SAFETY + CONTROL

AI must not:

- silently delete tasks
- silently modify important settings
- send messages
- make purchases
- change permissions
- block applications
- take consequential actions

without explicit user interaction.

The AI is an assistant, not an autonomous controller.

---

# 38. PHASE 3 ACCEPTANCE CRITERIA

- [ ] Natural-language task creation works
- [ ] Structured AI responses are validated
- [ ] AI errors are handled gracefully
- [ ] Tap-to-listen voice interaction works
- [ ] Dynamic Notch supports assistant states
- [ ] AI can summarize daily activity
- [ ] AI does not control deterministic system functionality
- [ ] AI failures do not break the application

---

# 39. PHASE 4 — REFLECTION + ADVANCED ATTENTION INTELLIGENCE

## Objective

Build the deeper mindfulness system.

Phase 4 includes:

- periodic check-ins
- journaling
- quotes/reflections
- behavioral insights
- Reel/Short detection experiments
- advanced statistics
- personalized interventions

---

# 40. PERIODIC CHECK-INS

Every few hours, optionally show:

```text
╭──────────────────────────────╮
│                              │
│        Quick check-in        │
│                              │
│        How's your day?       │
│                              │
│       🙂     😐     😔       │
│                              │
╰──────────────────────────────╯
```

The interaction should take only a few seconds.

Do not force long journaling.

---

# 41. JOURNALING

Allow short reflections.

Examples:

> How has your day been?

> What are you focused on right now?

> What's distracting you?

Responses should be stored locally unless the user explicitly enables cloud/AI processing.

Privacy should be treated as a major product concern.

---

# 42. QUOTES / REFLECTIONS

The Dynamic Notch can periodically expand:

```text
╭──────────────────────────────╮
│                              │
│   "Attention is a finite     │
│    resource."                │
│                              │
╰──────────────────────────────╯
```

The quote system should remain subtle.

Do not turn the application into a motivational quote feed.

---

# 43. ADVANCED INSIGHTS

Eventually generate insights such as:

```text
Your attention patterns

You tend to use social apps most
between 9:00 PM and 11:00 PM.

Your average unintentional
session is 18 minutes.

Your longest focused period
this week was 74 minutes.
```

Insights should be descriptive.

Avoid moral judgments.

---

# 44. REEL / SHORT DETECTION

This is experimental.

Do NOT assume Android provides a reliable API for:

> "Number of Instagram Reels watched."

If implemented, investigate accessibility/UI-based detection carefully.

Potential targets:

- Instagram Reels
- YouTube Shorts

The system should gracefully fall back to general application usage when detection is unavailable.

Example:

```text
Instagram
42m today

Estimated:
~31 short-form sessions
```

If the number is an estimate, label it as an estimate.

Never present inferred values as exact.

---

# 45. ADVANCED ANALYTICS

Eventually support:

- 7-day trends
- 30-day trends
- application categories
- session distribution
- time-of-day patterns
- intentional vs unintentional usage
- task completion
- attention trends
- mood/check-in correlations

Example:

```text
ATTENTION PATTERN

9 PM – 11 PM

Highest social media usage

TASK COMPLETION

Morning     ████████
Afternoon   █████
Evening     ███
```

The system should focus on helping the user understand patterns.

---

# 46. PHASE 4 ACCEPTANCE CRITERIA

- [ ] Check-ins work
- [ ] Journaling works
- [ ] Reflection content works
- [ ] Advanced statistics work
- [ ] Behavioral insights are descriptive
- [ ] Experimental short-form detection is isolated
- [ ] Estimated data is clearly labeled
- [ ] Privacy controls exist
- [ ] User can disable check-ins
- [ ] User can disable AI analysis

---

# 47. PRIVACY

This application deals with highly sensitive behavioral data.

Treat the following as sensitive:

- application usage
- screen time
- browsing/application patterns
- tasks
- habits
- journal entries
- mood/check-ins
- AI conversations

Default principle:

> **Keep user data on-device whenever possible.**

Do not introduce a backend simply because it is convenient.

Cloud synchronization should be a future opt-in feature.

---

# 48. BATTERY

This is an Android background application.

Battery consumption is critical.

Do not:

- poll every few milliseconds
- run unnecessary infinite loops
- constantly rebuild Flutter widgets
- repeatedly query UsageStats unnecessarily
- continuously capture the screen
- continuously use accessibility events without reason

Prefer:

- event-driven behavior
- reasonable polling intervals
- cached application metadata
- scheduled aggregation
- Android lifecycle awareness

---

# 49. PERFORMANCE

The Dynamic Notch must remain lightweight.

Avoid:

- rebuilding the entire application for every timer tick
- unnecessary network requests
- heavy animation rendering
- excessive blur
- huge image assets
- unnecessary background isolates

A usage timer can update efficiently.

---

# 50. ERROR HANDLING

The application must gracefully handle:

- usage permission denied
- overlay permission denied
- app unavailable
- Android restrictions
- service killed
- device reboot
- database corruption
- missing package metadata
- unsupported device behavior
- AI unavailable
- network unavailable

The application should never silently pretend tracking is working when it is not.

---

# 51. TESTING

Implement tests for:

## Unit

- duration calculations
- session aggregation
- midnight rollover
- daily statistics
- task parsing
- cooldown logic

## Integration

- Android usage tracking
- overlay lifecycle
- permission flow
- app switching

## Manual

Test:

- Instagram
- YouTube
- Chrome
- WhatsApp
- Reddit
- system settings
- lock/unlock
- reboot
- rapid app switching

---

# 52. DEVELOPMENT RULES FOR ANTIGRAVITY

AntiGravity MUST follow these rules.

## Rule 1 — Do not over-engineer

Build only what is required for the active phase.

---

## Rule 2 — Do not implement future phases early

Do not create:

- AI systems
- task systems
- journaling systems
- habit systems
- Reel detection

during Phase 1.

Architecture may support them.

Implementation may not.

---

## Rule 3 — Preserve working functionality

Before modifying a working system:

1. inspect it
2. understand it
3. make the smallest change
4. test it

Do not rewrite working components unnecessarily.

---

## Rule 4 — No fake functionality

Never use:

```text
fake screen time
fake app detection
fake statistics
fake AI responses
fake usage sessions
```

If functionality is unavailable, clearly expose the limitation.

---

## Rule 5 — No placeholder UI

Do not create meaningless placeholder cards.

Do not use:

```text
Lorem ipsum
Coming soon
AI-powered experience
Revolutionary productivity
```

unless explicitly required.

---

## Rule 6 — No generic AI slop

Avoid generic generated interfaces.

The design should have a deliberate visual identity.

---

## Rule 7 — No dark-mode neon AI aesthetic by default

Avoid:

- purple gradients
- cyan neon
- glowing borders
- excessive glassmorphism
- generic AI dashboard aesthetics

---

## Rule 8 — Dynamic Notch first

When working on the UI, prioritize the quality of the Dynamic Notch.

It is the defining feature.

---

# 53. GIT / VERSION CONTROL

Create logical commits.

Examples:

```text
feat: initialize flutter project
feat: implement usage statistics
feat: add app session tracking
feat: implement overlay permission flow
feat: add dynamic notch
feat: add usage dashboard
fix: handle midnight session rollover
fix: prevent duplicate overlay instances
```

Do not create giant commits containing unrelated changes.

---

# 54. DOCUMENTATION

Maintain documentation for:

- Android permissions
- UsageStats implementation
- overlay architecture
- database schema
- state machine
- Dynamic Notch animations
- known Android limitations

Document important platform-specific decisions.

---

# 55. DEVELOPMENT PHASE CONTROL

The project should expose the current development phase clearly.

At the beginning of every major task, determine:

```text
CURRENT PHASE:
Phase 1 / Phase 2 / Phase 3 / Phase 4
```

If the requested feature belongs to a later phase:

Do not implement it automatically.

Instead, determine whether a small architectural preparation is required.

Example:

> Phase 1 request: "Add AI voice assistant."

Response:

The feature belongs to Phase 3.

Do not implement it.

If necessary, create only an interface such as:

```dart
abstract class AssistantService {}
```

and continue with Phase 1.

---

# 56. DEFINITION OF DONE

A phase is NOT complete merely because the code compiles.

A phase is complete when:

1. functionality works on a real Android device
2. permissions work
3. lifecycle behavior works
4. data persists correctly
5. UI behaves correctly
6. animations are polished
7. common failure states are handled
8. no obvious crashes exist
9. tests pass
10. documentation reflects the current implementation

---

# 57. FINAL PRODUCT VISION

The eventual application should feel like:

> **A small intelligent layer between the user and their phone.**

The user should not feel monitored.

They should feel accompanied.

The Dynamic Notch should become the recognizable identity of the product.

The eventual interaction model:

```text
                     PHONE
                       │
                       ▼
              ┌─────────────────┐
              │ Dynamic Notch   │
              └────────┬────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
       Attention      Intent      Reflection
          │            │            │
          ▼            ▼            ▼
       Usage        Tasks/Habits   Check-ins
          │            │            │
          └────────────┼────────────┘
                       │
                       ▼
                 AI COMPANION
```

The product should ultimately answer one question:

> **"Am I spending my attention on what I actually want to be doing?"**

without deciding the answer for the user.

---

# 58. CURRENT IMPLEMENTATION TARGET

## BUILD ONLY PHASE 1 NOW.

The immediate objective is:

### A working Android Flutter application that:

1. detects app usage
2. records usage sessions
3. calculates daily statistics
4. displays statistics in the main application
5. displays a Dynamic Notch overlay
6. detects when a tracked application becomes active
7. shows that application's usage in the Dynamic Notch
8. smoothly expands and collapses
9. persists data
10. handles Android permissions correctly
11. works reliably on a physical Android device

Once this is stable, stop.

Do NOT proceed to Phase 2 automatically.

Wait for explicit approval before beginning the next phase.

---

# 59. FIRST TASK FOR ANTIGRAVITY

Before writing implementation code:

1. Inspect the repository.
2. Confirm whether this is a clean Flutter project.
3. Inspect Flutter/Dart versions.
4. Inspect Android configuration.
5. Confirm minimum Android SDK.
6. Determine the appropriate Android implementation strategy for UsageStats.
7. Determine the appropriate overlay implementation strategy.
8. Propose the project structure.
9. Identify required Android permissions.
10. Identify platform limitations.
11. Create a concise implementation plan for Phase 1.

Do NOT start Phase 2.

Do NOT add AI.

Do NOT add task management.

Do NOT add Reel/Short detection.

Do NOT add journaling.

Do NOT add habits.

Do NOT add unnecessary backend infrastructure.

After the architecture is reviewed, implement Phase 1 incrementally.

---

# 60. MOST IMPORTANT INSTRUCTION

**Build the smallest version that proves the core idea.**

The success of this project is not determined by how many features exist.

It is determined by whether this interaction feels magical:

```text
User opens Instagram

        ↓

Dynamic Notch appears

        ↓

Instagram · 18m today

        ↓

User keeps scrolling

        ↓

Notch subtly updates

        ↓

User eventually sees:

18m today
```

The user should think:

> **"Holy shit, my phone is actually making me aware of what I'm doing."**

That feeling is the product.

Everything else comes later.