import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class TaskDialog extends StatefulWidget {
  final Function({
    required String title,
    String? description,
    String? deadline,
    int priority,
  }) onSave;

  const TaskDialog({super.key, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    required Function({
      required String title,
      String? description,
      String? deadline,
      int priority,
    }) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => TaskDialog(onSave: onSave),
    );
  }

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _deadlineController = TextEditingController();
  int _priority = 1;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _deadlineController.dispose();
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
        'Add Task',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g. Finish DB assignment',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Chapter 4 and queries',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deadlineController,
              decoration: const InputDecoration(
                labelText: 'Deadline (optional)',
                hintText: 'e.g. 22:00 or 7:00 PM',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Priority:',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Normal'),
                  selected: _priority == 1,
                  onSelected: (val) {
                    if (val) setState(() => _priority = 1);
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('High Focus'),
                  selected: _priority == 2,
                  onSelected: (val) {
                    if (val) setState(() => _priority = 2);
                  },
                ),
              ],
            ),
          ],
        ),
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
              widget.onSave(
                title: title,
                description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                deadline: _deadlineController.text.trim().isEmpty ? null : _deadlineController.text.trim(),
                priority: _priority,
              );
            }
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.oliveGreen,
          ),
          child: const Text('Add Task'),
        ),
      ],
    );
  }
}
