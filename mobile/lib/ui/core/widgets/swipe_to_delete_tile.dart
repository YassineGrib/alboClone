import 'package:flutter/material.dart';
import 'package:later/ui/core/theme/later_theme.dart';

class SwipeToDeleteTile extends StatelessWidget {
  const SwipeToDeleteTile({
    super.key,
    required this.itemKey,
    required this.onDismissed,
    this.onMove,
    required this.child,
  });

  final Key itemKey;
  final VoidCallback onDismissed;
  final VoidCallback? onMove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMove = onMove != null;

    return Dismissible(
      key: itemKey,
      direction: hasMove ? DismissDirection.horizontal : DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onMove?.call();
          return false;
        }
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete save?'),
                content: Text(
                  'Are you sure you want to delete this saved item?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: LaterColors.chipFailedFg,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDismissed();
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(
              Icons.drive_file_move_outlined,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Move',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: LaterColors.chipFailedBg,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: LaterColors.chipFailedFg,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: LaterColors.chipFailedFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}
