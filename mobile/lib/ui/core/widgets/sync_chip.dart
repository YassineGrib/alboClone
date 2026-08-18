import 'package:flutter/material.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/ui/core/theme/later_theme.dart';

class SyncChip extends StatelessWidget {
  const SyncChip({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      SyncStatus.pendingSync => ('Pending', LaterColors.chipPendingBg, LaterColors.chipPendingFg),
      SyncStatus.synced => ('Synced', LaterColors.chipSyncedBg, LaterColors.chipSyncedFg),
      SyncStatus.syncFailed => ('Failed', LaterColors.chipFailedBg, LaterColors.chipFailedFg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
