import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/recording_entity.dart';
import '../../shared/widgets/sync_status_badge.dart';

class RecordingTile extends StatelessWidget {
  final RecordingEntity recording;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const RecordingTile({
    super.key,
    required this.recording,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.graphic_eq_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          Formatters.duration(recording.duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Text(' · '),
                        Text(
                          Formatters.relative(recording.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Text(' · '),
                        Text(
                          Formatters.fileSize(recording.sizeBytes),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 6),
                        SyncStatusBadge(synced: recording.synced),
                      ],
                    ),
                    if (recording.hasNoiseRemoval ||
                        recording.hasThemeApplied) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (recording.hasNoiseRemoval)
                            const _MiniChip(label: 'Denoised'),
                          if (recording.hasThemeApplied)
                            const _MiniChip(label: 'Theme applied'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
