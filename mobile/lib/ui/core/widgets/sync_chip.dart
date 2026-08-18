import 'package:flutter/material.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/ui/core/theme/later_theme.dart';

class SyncChip extends StatelessWidget {
  const SyncChip({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fullLabel, bg, fg) = switch (status) {
      SyncStatus.pendingSync => ('P', 'Pending sync', LaterColors.chipPendingBg, LaterColors.chipPendingFg),
      SyncStatus.synced => ('S', 'Synced', LaterColors.chipSyncedBg, LaterColors.chipSyncedFg),
      SyncStatus.syncFailed => ('F', 'Sync failed', LaterColors.chipFailedBg, LaterColors.chipFailedFg),
    };

    return Tooltip(
      message: fullLabel,
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
