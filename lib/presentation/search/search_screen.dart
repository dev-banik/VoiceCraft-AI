import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../dashboard/widgets/recording_tile.dart';
import '../shared/widgets/empty_state.dart';
import 'controller/search_controller.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search recordings…',
            border: InputBorder.none,
          ),
          onChanged: (value) => ref
              .read(searchFiltersProvider.notifier)
              .update((s) => s.copyWith(query: value)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Noise Removed'),
                  selected: filters.noiseRemovedOnly,
                  onSelected: (v) => ref
                      .read(searchFiltersProvider.notifier)
                      .update((s) => s.copyWith(noiseRemovedOnly: v)),
                ),
                FilterChip(
                  label: const Text('Theme Applied'),
                  selected: filters.themeAppliedOnly,
                  onSelected: (v) => ref
                      .read(searchFiltersProvider.notifier)
                      .update((s) => s.copyWith(themeAppliedOnly: v)),
                ),
                FilterChip(
                  label: const Text('Synced'),
                  selected: filters.syncedOnly,
                  onSelected: (v) => ref
                      .read(searchFiltersProvider.notifier)
                      .update((s) => s.copyWith(syncedOnly: v)),
                ),
                FilterChip(
                  label: const Text('Local Only'),
                  selected: filters.localOnly,
                  onSelected: (v) => ref
                      .read(searchFiltersProvider.notifier)
                      .update((s) => s.copyWith(localOnly: v)),
                ),
              ],
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (results) {
                if (results.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message: 'Try a different name or clear your filters.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final r = results[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RecordingTile(
                        recording: r,
                        onTap: () =>
                            context.push(RoutePaths.playbackPath(r.id)),
                        onMore: () {},
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
