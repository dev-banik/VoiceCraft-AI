import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/router/route_names.dart';
import '../../domain/entities/recording_entity.dart';
import '../auth/sign_in_sheet.dart';
import '../shared/widgets/empty_state.dart';
import 'controller/dashboard_controller.dart';
import 'widgets/recording_tile.dart';
import 'widgets/storage_safety_card.dart';
import 'widgets/storage_summary_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(recordingsStreamProvider);
    final totalCount = ref.watch(totalRecordingsCountProvider);
    final totalBytes = ref.watch(totalStorageBytesProvider).valueOrNull ?? 0;
    final isSignedIn = ref.watch(isSignedInProvider);
    final filters = ref.watch(libraryFiltersProvider);
    final visible = ref.watch(visibleRecordingsProvider);
    final tabCounts = ref.watch(libraryTabCountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VoiceCraft AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(RoutePaths.search),
          ),
          IconButton(
            icon: Icon(
              isSignedIn ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
            ),
            tooltip: isSignedIn ? 'Cloud sync' : 'Backup my recordings',
            onPressed: () => showSignInSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: recordingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Something went wrong: $e')),
          data: (recordings) {
            if (recordings.isEmpty) {
              return const EmptyState(
                icon: Icons.mic_none_rounded,
                title: 'No recordings yet',
                message:
                    'Tap the + button to record your first take. It stays on '
                    'this device until you choose to back it up.',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const StorageSafetyCard(),
                StorageSummaryCard(
                  totalRecordings: totalCount,
                  recentCount: recordings
                      .where((r) => DateTime.now()
                          .difference(r.createdAt)
                          .inHours < 24)
                      .length,
                  totalStorageBytes: totalBytes,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<LibraryTab>(
                    showSelectedIcon: false,
                    segments: [
                      for (final tab in LibraryTab.values)
                        ButtonSegment(
                          value: tab,
                          label: Text('${tab.label} (${tabCounts[tab] ?? 0})'),
                        ),
                    ],
                    selected: {filters.tab},
                    onSelectionChanged: (selection) => ref
                        .read(libraryFiltersProvider.notifier)
                        .update((f) => f.copyWith(tab: selection.first)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Denoised'),
                      selected: filters.denoisedOnly,
                      onSelected: (v) => ref
                          .read(libraryFiltersProvider.notifier)
                          .update((f) => f.copyWith(denoisedOnly: v)),
                    ),
                    FilterChip(
                      label: const Text('Theme applied'),
                      selected: filters.themeAppliedOnly,
                      onSelected: (v) => ref
                          .read(libraryFiltersProvider.notifier)
                          .update((f) => f.copyWith(themeAppliedOnly: v)),
                    ),
                    if (filters.hasChipFilter)
                      ActionChip(
                        avatar: const Icon(Icons.clear_rounded, size: 18),
                        label: const Text('Clear'),
                        onPressed: () => ref
                            .read(libraryFiltersProvider.notifier)
                            .update(
                              (f) => f.copyWith(
                                denoisedOnly: false,
                                themeAppliedOnly: false,
                              ),
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _listHeading(filters),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      _emptyMessage(filters),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  ...visible.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RecordingTile(
                        recording: r,
                        onTap: () =>
                            context.push(RoutePaths.playbackPath(r.id)),
                        onMore: () => _showActions(context, ref, r),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.record),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  String _listHeading(LibraryFilters filters) {
    switch (filters.tab) {
      case LibraryTab.all:
        return 'Your recordings';
      case LibraryTab.modified:
        return 'Modified recordings';
      case LibraryTab.originals:
        return 'Originals you replaced';
    }
  }

  String _emptyMessage(LibraryFilters filters) {
    if (filters.hasChipFilter) {
      return 'No recordings here match those filters.';
    }
    switch (filters.tab) {
      case LibraryTab.all:
        return 'No recordings yet.';
      case LibraryTab.modified:
        return 'Nothing here yet. When you process a recording and choose '
            '"Save as a new recording", it lands on this tab.';
      case LibraryTab.originals:
        return 'Nothing here yet. When you replace a recording with a '
            'processed version, the untouched take is kept here.';
    }
  }

  void _showActions(
    BuildContext context,
    WidgetRef ref,
    RecordingEntity recording,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.graphic_eq_rounded),
                title: const Text('Remove noise'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RoutePaths.noiseRemovalPath(recording.id));
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: const Text('Voice themes'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RoutePaths.voiceThemesPath(recording.id));
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Clarity enhancement'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RoutePaths.enhancementPath(recording.id));
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_cut_rounded),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RoutePaths.editorPath(recording.id));
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline_rounded),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRenameDialog(context, ref, recording);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await ref
                      .read(recordingUsecasesProvider)
                      .delete(recording.id);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    RecordingEntity recording,
  ) {
    final controller = TextEditingController(text: recording.title);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename recording'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              Navigator.pop(dialogContext);
              if (newTitle.isEmpty) return;
              await ref
                  .read(recordingUsecasesProvider)
                  .rename(recording.id, newTitle);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
