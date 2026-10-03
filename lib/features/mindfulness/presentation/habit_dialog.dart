import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class HabitDialog extends StatefulWidget {
  final Function(String title, String frequency) onSave;

  const HabitDialog({super.key, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    required Function(String title, String frequency) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => HabitDialog(onSave: onSave),
    );
  }

  @override
  State<HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends State<HabitDialog> {
  final _titleController = TextEditingController();
  String _frequency = 'daily';

  @override
  void dispose() {
    _titleController.dispose();
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
        'New Mindful Habit',
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
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Habit Name',
              hintText: 'e.g. Read 20 pages, Morning walk, Meditate',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Daily'),
                selected: _frequency == 'daily',
                onSelected: (val) {
                  if (val) setState(() => _frequency = 'daily');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Weekdays'),
                selected: _frequency == 'weekdays',
                onSelected: (val) {
                  if (val) setState(() => _frequency = 'weekdays');
                },
              ),
            ],
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
            final title = _titleController.text.trim();
            if (title.isNotEmpty) {
              widget.onSave(title, _frequency);
            }
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.oliveGreen,
          ),
          child: const Text('Add Habit'),
        ),
      ],
    );
  }
}
