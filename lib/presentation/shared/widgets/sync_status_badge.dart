import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SyncStatusBadge extends StatelessWidget {
  final bool synced;

  const SyncStatusBadge({super.key, required this.synced});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: synced ? 'Synced to cloud' : 'Local only',
      child: Icon(
        synced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
        size: 16,
        color: synced ? AppColors.cloudSynced : AppColors.localOnly,
      ),
    );
  }
}
