import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/storage_location.dart';
import '../../../data/datasources/local/library_recovery.dart';
import '../controller/dashboard_controller.dart';

/// Whether recordings are currently being kept somewhere that survives an
/// uninstall. Re-read rather than cached, since the user can revoke the
/// permission from system settings at any time.
final FutureProvider<bool> sharedStorageGrantedProvider =
    FutureProvider<bool>((ref) => StorageLocation.hasSharedAccess());

/// Offers to move the library out of app-private storage.
///
/// Shown until the permission is granted, and deliberately not dismissible:
/// the cost of ignoring it is silently losing every recording the next time
/// the app is uninstalled or its data cleared, which is not something the
/// user finds out about until it has already happened.
class StorageSafetyCard extends ConsumerStatefulWidget {
  const StorageSafetyCard({super.key});

  @override
  ConsumerState<StorageSafetyCard> createState() => _StorageSafetyCardState();
}

class _StorageSafetyCardState extends ConsumerState<StorageSafetyCard> {
  bool _working = false;

  Future<void> _enable() async {
    setState(() => _working = true);
    try {
      final granted = await StorageLocation.requestSharedAccess();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission not granted — recordings are still stored inside '
              'the app.',
            ),
          ),
        );
        return;
      }

      StorageLocation.invalidate();
      await LibraryRecovery.migrateToSharedStorage();
      if (!mounted) return;

      ref.invalidate(sharedStorageGrantedProvider);
      ref.invalidate(recordingsStreamProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recordings moved to the VoiceCraft AI folder. They will survive '
            'uninstalling the app.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final granted = ref.watch(sharedStorageGrantedProvider).valueOrNull;
    if (granted == null || granted) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep your recordings safe',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Recordings are stored inside the app, so uninstalling it or '
            'clearing its data deletes them. Move them to a '
            '"${StorageLocation.folderName}" folder on your phone and they '
            'stay put — no cloud account needed.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: _working
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.drive_file_move_outline_rounded),
              label: Text(_working ? 'Moving…' : 'Move them out'),
              onPressed: _working ? null : _enable,
            ),
          ),
        ],
      ),
    );
  }
}
