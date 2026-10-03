import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../domain/notch_state.dart';

class DynamicNotchPill extends StatefulWidget {
  final NotchState state;
  final String appName;
  final Duration todayDuration;
  final Duration sessionDuration;
  final String? activeTaskTitle;
  final String? assistantMessage;
  final String? reflectionQuote;
  final ValueChanged<NotchState>? onStateChanged;
  final VoidCallback? onBackToTask;
  final ValueChanged<bool>? onClassifySession;
  final ValueChanged<String>? onCheckInResponse;

  const DynamicNotchPill({
    super.key,
    this.state = NotchState.collapsed,
    this.appName = 'Instagram',
    this.todayDuration = const Duration(minutes: 18),
    this.sessionDuration = const Duration(minutes: 5),
    this.activeTaskTitle,
    this.assistantMessage,
    this.reflectionQuote,
    this.onStateChanged,
    this.onBackToTask,
    this.onClassifySession,
    this.onCheckInResponse,
  });

  @override
  State<DynamicNotchPill> createState() => _DynamicNotchPillState();
}

class _DynamicNotchPillState extends State<DynamicNotchPill>
    with SingleTickerProviderStateMixin {
  late NotchState _currentState;
  int _expandedPageIndex = 0;
  Timer? _autoCollapseTimer;

  // Pulse animation for assistant listening state
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_currentState == NotchState.assistantListening) {
      _pulseController.repeat(reverse: true);
    }
    _checkAutoCollapse();
  }

  @override
  void didUpdateWidget(covariant DynamicNotchPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      setState(() {
        _currentState = widget.state;
      });
      _syncPulseController();
      _checkAutoCollapse();
    }
  }

  void _syncPulseController() {
    if (_currentState == NotchState.assistantListening) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkAutoCollapse() {
    _autoCollapseTimer?.cancel();
    int delaySeconds = 0;

    switch (_currentState) {
      case NotchState.appDetected:
        delaySeconds = 4;
        break;
      case NotchState.usageDisplay:
        delaySeconds = 5;
        break;
      case NotchState.assistantResponding:
        delaySeconds = 5;
        break;
      case NotchState.reflection:
        delaySeconds = 7;
        break;
      case NotchState.contextualNudge:
        delaySeconds = 10;
        break;
      default:
        delaySeconds = 0;
    }

    if (delaySeconds > 0) {
      _autoCollapseTimer = Timer(Duration(seconds: delaySeconds), () {
        if (mounted && _currentState != NotchState.collapsed) {
          _transitionTo(NotchState.collapsed);
        }
      });
    }
  }

  void _transitionTo(NotchState next) {
    setState(() {
      _currentState = next;
      if (next == NotchState.expanded) {
        _expandedPageIndex = 0;
      }
    });
    _syncPulseController();
    widget.onStateChanged?.call(next);
    _checkAutoCollapse();
  }

  void _onPillTap() {
    switch (_currentState) {
      case NotchState.collapsed:
        _transitionTo(NotchState.expanded);
        break;
      case NotchState.expanded:
        _transitionTo(NotchState.collapsed);
        break;
      case NotchState.appDetected:
      case NotchState.usageDisplay:
        _transitionTo(NotchState.expanded);
        break;
      case NotchState.contextualNudge:
        _transitionTo(NotchState.collapsed);
        break;
      case NotchState.checkIn:
        _transitionTo(NotchState.expanded);
        break;
      default:
        _transitionTo(NotchState.collapsed);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine dynamic target width & height
    double targetWidth;
    double targetHeight;

    switch (_currentState) {
      case NotchState.dormant:
        targetWidth = 18;
        targetHeight = 18;
        break;
      case NotchState.collapsed:
        targetWidth = 84;
        targetHeight = 28;
        break;
      case NotchState.appDetected:
        targetWidth = 220;
        targetHeight = 38;
        break;
      case NotchState.usageDisplay:
        targetWidth = 240;
        targetHeight = 38;
        break;
      case NotchState.expanded:
        targetWidth = 310;
        targetHeight = 156;
        break;
      case NotchState.contextualNudge:
        targetWidth = 320;
        targetHeight = 160;
        break;
      case NotchState.assistantListening:
        targetWidth = 210;
        targetHeight = 42;
        break;
      case NotchState.assistantProcessing:
        targetWidth = 190;
        targetHeight = 40;
        break;
      case NotchState.assistantResponding:
        targetWidth = 290;
        targetHeight = 110;
        break;
      case NotchState.checkIn:
        targetWidth = 300;
        targetHeight = 140;
        break;
      case NotchState.reflection:
        targetWidth = 290;
        targetHeight = 100;
        break;
    }

    final double cornerRadius = (_currentState == NotchState.dormant)
        ? 9
        : (_currentState == NotchState.collapsed)
            ? 14
            : (_currentState == NotchState.appDetected ||
                    _currentState == NotchState.usageDisplay ||
                    _currentState == NotchState.assistantListening ||
                    _currentState == NotchState.assistantProcessing)
                ? 19
                : 26;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: targetWidth,
        height: targetHeight,
        decoration: BoxDecoration(
          color: AppColors.notchPillBackground,
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(
            color: AppColors.notchBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onPillTap,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: _buildStateContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_currentState) {
      case NotchState.dormant:
        return const SizedBox(
          key: ValueKey('dormant'),
          width: 8,
          height: 8,
        );

      case NotchState.collapsed:
        return Row(
          key: const ValueKey('collapsed'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.oliveGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              Formatters.formatDuration(widget.todayDuration),
              style: const TextStyle(
                color: AppColors.notchTextPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case NotchState.appDetected:
        return Row(
          key: const ValueKey('appDetected'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_android_rounded,
              color: AppColors.notchTextSecondary,
              size: 15,
            ),
            const SizedBox(width: 7),
            Text(
              widget.appName,
              style: const TextStyle(
                color: AppColors.notchTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '· ${Formatters.formatDuration(widget.todayDuration)}',
              style: const TextStyle(
                color: AppColors.notchTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );

      case NotchState.usageDisplay:
        return Row(
          key: const ValueKey('usageDisplay'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.appName,
              style: const TextStyle(
                color: AppColors.notchTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${Formatters.formatDuration(widget.todayDuration)} today',
              style: const TextStyle(
                color: AppColors.notchTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );

      case NotchState.expanded:
        return GestureDetector(
          key: const ValueKey('expanded'),
          onHorizontalDragEnd: (details) {
            final vx = details.primaryVelocity ?? 0;
            if (vx < -120 && _expandedPageIndex < 2) {
              setState(() => _expandedPageIndex++);
            } else if (vx > 120 && _expandedPageIndex > 0) {
              setState(() => _expandedPageIndex--);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_expandedPageIndex == 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.appName,
                        style: const TextStyle(
                          color: AppColors.notchTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Today: ${Formatters.formatDuration(widget.todayDuration)}',
                        style: const TextStyle(
                          color: AppColors.notchTextSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Current session: ${Formatters.formatDuration(widget.sessionDuration)}',
                    style: const TextStyle(
                      color: AppColors.notchTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPillButton(
                        label: 'Intentional',
                        color: AppColors.intentionalGreen,
                        onTap: () {
                          widget.onClassifySession?.call(true);
                          _transitionTo(NotchState.collapsed);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton(
                        label: 'Unintentional',
                        color: AppColors.unintentionalWarm,
                        onTap: () {
                          widget.onClassifySession?.call(false);
                          _transitionTo(NotchState.collapsed);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton(
                        label: 'Dismiss',
                        color: const Color(0xFF262529),
                        onTap: () => _transitionTo(NotchState.collapsed),
                      ),
                    ],
                  ),
                ] else if (_expandedPageIndex == 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.appName,
                        style: const TextStyle(
                          color: AppColors.notchTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        "TODAY'S PRIORITIES",
                        style: TextStyle(
                          color: AppColors.notchTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.activeTaskTitle != null
                        ? '○ ${widget.activeTaskTitle}'
                        : 'No open priorities today.\nStay mindful of your presence.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.notchTextPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _buildPillButton(
                    label: 'Return to Focus',
                    color: AppColors.oliveGreen,
                    onTap: () {
                      widget.onBackToTask?.call();
                      _transitionTo(NotchState.collapsed);
                    },
                  ),
                ] else ...[
                  const Text(
                    'PAUSE & REFLECT',
                    style: TextStyle(
                      color: AppColors.notchTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '“${widget.reflectionQuote ?? 'The attention you give something is the life you give it.'}”',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.notchTextPrimary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                  _buildPillButton(
                    label: 'Close',
                    color: const Color(0xFF262529),
                    onTap: () => _transitionTo(NotchState.collapsed),
                  ),
                ],
                // Subtle page dots inside the pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isActive = index == _expandedPageIndex;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 6 : 4,
                      height: isActive ? 6 : 4,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.notchTextPrimary : AppColors.notchBorder,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );

      case NotchState.contextualNudge:
        final task = widget.activeTaskTitle ?? 'your intended priority';
        return Padding(
          key: const ValueKey('contextualNudge'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.appName} · ${Formatters.formatDuration(widget.sessionDuration)}',
                    style: const TextStyle(
                      color: AppColors.notchTextSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                'You planned to focus on:\n"$task"\nBack to it?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.notchTextPrimary,
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPillButton(
                    label: 'Return to Focus',
                    color: AppColors.oliveGreen,
                    onTap: () {
                      widget.onBackToTask?.call();
                      _transitionTo(NotchState.collapsed);
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildPillButton(
                    label: 'Stay 5m',
                    color: const Color(0xFF262529),
                    onTap: () => _transitionTo(NotchState.collapsed),
                  ),
                ],
              ),
            ],
          ),
        );

      case NotchState.assistantListening:
        return Row(
          key: const ValueKey('assistantListening'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.oliveGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              "I'm listening",
              style: TextStyle(
                color: AppColors.notchTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              '● ● ●',
              style: TextStyle(
                color: AppColors.notchTextSecondary,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        );

      case NotchState.assistantProcessing:
        return const Row(
          key: ValueKey('assistantProcessing'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Reflecting',
              style: TextStyle(
                color: AppColors.notchTextPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '✦',
              style: TextStyle(
                color: AppColors.warmOchre,
                fontSize: 14,
              ),
            ),
          ],
        );

      case NotchState.assistantResponding:
        final msg = widget.assistantMessage ?? 'Task captured into your mindful plan.';
        return Padding(
          key: const ValueKey('assistantResponding'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Mindful Companion',
                style: TextStyle(
                  color: AppColors.notchTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.notchTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );

      case NotchState.checkIn:
        return Padding(
          key: const ValueKey('checkIn'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'How does your attention feel right now?',
                style: TextStyle(
                  color: AppColors.notchTextPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPillButton(
                    label: 'Focused 🙂',
                    color: AppColors.oliveGreen,
                    onTap: () {
                      widget.onCheckInResponse?.call('focused');
                      _transitionTo(NotchState.collapsed);
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildPillButton(
                    label: 'Wandering 😐',
                    color: AppColors.warmOchre,
                    onTap: () {
                      widget.onCheckInResponse?.call('wandering');
                      _transitionTo(NotchState.collapsed);
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildPillButton(
                    label: 'Distracted 😔',
                    color: AppColors.terracotta,
                    onTap: () {
                      widget.onCheckInResponse?.call('distracted');
                      _transitionTo(NotchState.collapsed);
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case NotchState.reflection:
        final quote = widget.reflectionQuote ??
            'Attention is your most sacred non-renewable resource.';
        return Padding(
          key: const ValueKey('reflection'),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PAUSE & REFLECT',
                style: TextStyle(
                  color: AppColors.notchTextSecondary,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '"$quote"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.notchTextPrimary,
                  fontSize: 12.5,
                  height: 1.3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPillButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
