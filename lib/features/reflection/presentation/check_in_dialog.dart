import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class CheckInDialog extends StatefulWidget {
  final Function(String mood, int score, String? note) onSave;

  const CheckInDialog({super.key, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    required Function(String mood, int score, String? note) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CheckInDialog(onSave: onSave),
    );
  }

  @override
  State<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<CheckInDialog> {
  String _selectedMood = 'focused';
  int _score = 5;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Mindful Check-in',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How does your attention feel right now?',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMoodOption(
                label: 'Focused',
                emoji: '🙂',
                mood: 'focused',
                score: 5,
                color: AppColors.oliveGreen,
              ),
              _buildMoodOption(
                label: 'Wandering',
                emoji: '😐',
                mood: 'wandering',
                score: 3,
                color: AppColors.warmOchre,
              ),
              _buildMoodOption(
                label: 'Distracted',
                emoji: '😔',
                mood: 'distracted',
                score: 1,
                color: AppColors.terracotta,
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Optional reflection note',
              hintText: 'What caught your attention?',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(
              _selectedMood,
              _score,
              _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            );
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.oliveGreen,
          ),
          child: const Text('Record Check-in'),
        ),
      ],
    );
  }

  Widget _buildMoodOption({
    required String label,
    required String emoji,
    required String mood,
    required int score,
    required Color color,
  }) {
    final isSelected = _selectedMood == mood;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
          _score = score;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
