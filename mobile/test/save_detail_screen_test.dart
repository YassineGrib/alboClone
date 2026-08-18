import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/features/saves/save_detail_screen.dart';

void main() {
  testWidgets('SaveDetailScreen renders details, direct link button, AI summary and metadata', (tester) async {
    final item = SaveItem(
      id: 'detail-test-1',
      url: 'https://flutter.dev',
      title: 'Flutter - Build apps for any screen',
      aiSummary: 'Flutter is Google framework for cross platform apps.',
      category: 'Article',
      aiTags: const ['flutter', 'dart', 'mobile'],
      contentStatus: ContentStatus.ready,
      syncStatus: SyncStatus.synced,
      createdAt: DateTime(2026, 8, 18, 20, 45),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LaterTheme.light(),
        home: SaveDetailScreen(item: item, folderName: 'Global'),
      ),
    );

    // Verify title and badges
    expect(find.text('Flutter - Build apps for any screen'), findsOneWidget);
    expect(find.text('Article'), findsOneWidget);
    expect(find.text('Gemini AI Summary'), findsOneWidget);

    // Scroll to see Open Link and metadata
    await tester.scrollUntilVisible(find.text('Open Link'), 100);
    expect(find.text('Open Link'), findsOneWidget);
    expect(find.textContaining('Flutter is Google framework'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Global'), 100);
    expect(find.text('Global'), findsOneWidget);
  });
}
