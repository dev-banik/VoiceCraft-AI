import 'package:flutter/material.dart';

import '../recording_mutations.dart';

/// Asks whether a processed take should go over the recording or beside it.
///
/// Returns null if the user backs out. Both options are spelled out in terms
/// of what happens to the audio rather than as bare verbs, because "replace"
/// sounds destructive and here it isn't — the previous take is archived.
Future<DerivativeSaveMode?> showSaveModeDialog(
  BuildContext context, {
  required String what,
}) {
  return showDialog<DerivativeSaveMode>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: Text('Save $what'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to keep it?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _Choice(
              icon: Icons.swap_horiz_rounded,
              title: 'Replace this recording',
              subtitle:
                  'The processed audio takes its place. The untouched take '
                  'is kept under Originals, so you can always go back.',
              onTap: () => Navigator.pop(
                dialogContext,
                DerivativeSaveMode.replace,
              ),
            ),
            const SizedBox(height: 8),
            _Choice(
              icon: Icons.library_add_rounded,
              title: 'Save as a new recording',
              subtitle:
                  'Keeps this recording as it is and adds the processed '
                  'audio to Modified.',
              onTap: () => Navigator.pop(
                dialogContext,
                DerivativeSaveMode.saveAsNew,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

class _Choice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Choice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
