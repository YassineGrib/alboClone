import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/sync_chip.dart';

void main() {
  testWidgets('SyncChip shows single letter status indicator (S, P, F)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LaterTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              SyncChip(status: SyncStatus.synced),
              SyncChip(status: SyncStatus.pendingSync),
              SyncChip(status: SyncStatus.syncFailed),
            ],
          ),
        ),
      ),
    );

    expect(find.text('S'), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
  });
}
