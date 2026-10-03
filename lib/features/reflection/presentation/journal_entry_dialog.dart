import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class JournalEntryDialog extends StatefulWidget {
  final Function(String title, String content, String? promptType) onSave;

  const JournalEntryDialog({super.key, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    required Function(String title, String content, String? promptType) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => JournalEntryDialog(onSave: onSave),
    );
  }

  @override
  State<JournalEntryDialog> createState() => _JournalEntryDialogState();
}

class _JournalEntryDialogState extends State<JournalEntryDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _promptType = 'Focus';

  final List<String> _prompts = [
    'What was on your mind?',
    'What distracted you today?',
    'A quiet moment worth remembering',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = _prompts.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
        'Mindful Reflection',
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
            Wrap(
              spacing: 6,
              children: _prompts.map((p) {
                final isSelected = _titleController.text == p;
                return ChoiceChip(
                  label: Text(p, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _titleController.text = p;
                        _promptType = p;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Prompt / Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Your thoughts',
                hintText: 'A few private, mindful sentences...',
              ),
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
            final content = _contentController.text.trim();
            if (content.isNotEmpty) {
              widget.onSave(
                title.isEmpty ? 'Reflection' : title,
                content,
                _promptType,
              );
            }
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.oliveGreen,
          ),
          child: const Text('Save Entry'),
        ),
      ],
    );
  }
}
