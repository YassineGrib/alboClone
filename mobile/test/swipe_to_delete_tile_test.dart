import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/swipe_to_delete_tile.dart';

void main() {
  testWidgets('SwipeToDeleteTile presents confirmation dialog on swipe and deletes when confirmed', (tester) async {
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: LaterTheme.light(),
        home: Scaffold(
          body: SwipeToDeleteTile(
            itemKey: const ValueKey('item-1'),
            onDismissed: () {
              deleted = true;
            },
            child: const ListTile(title: Text('Test Save Item')),
          ),
        ),
      ),
    );

    expect(find.text('Test Save Item'), findsOneWidget);

    // Swipe right to left
    await tester.drag(find.text('Test Save Item'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(find.text('Delete save?'), findsOneWidget);

    // Tap confirm Delete button
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });

  testWidgets('SwipeToDeleteTile cancels deletion when Cancel button is tapped in dialog', (tester) async {
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: LaterTheme.light(),
        home: Scaffold(
          body: SwipeToDeleteTile(
            itemKey: const ValueKey('item-2'),
            onDismissed: () {
              deleted = true;
            },
            child: const ListTile(title: Text('Test Cancel Item')),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Test Cancel Item'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete save?'), findsOneWidget);

    // Tap Cancel button
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(find.text('Test Cancel Item'), findsOneWidget);
  });

  testWidgets('SwipeToDeleteTile triggers onMove callback when swiped left to right', (tester) async {
    bool moved = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: LaterTheme.light(),
        home: Scaffold(
          body: SwipeToDeleteTile(
            itemKey: const ValueKey('item-3'),
            onDismissed: () {},
            onMove: () {
              moved = true;
            },
            child: const ListTile(title: Text('Test Move Item')),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Test Move Item'), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(moved, isTrue);
  });
}
