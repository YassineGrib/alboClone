import 'package:flutter_test/flutter_test.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/domain/models/save_query.dart';
import 'package:later/domain/save_timeline.dart';
import 'package:later/domain/source_app.dart';

SaveItem _save({
  required String id,
  String title = 'Grilled peaches',
  String url = 'https://example.com/peach',
  String? collectionId,
  ContentStatus status = ContentStatus.ready,
  DateTime? createdAt,
}) {
  return SaveItem(
    id: id,
    url: url,
    title: title,
    collectionId: collectionId,
    contentStatus: status,
    syncStatus: SyncStatus.synced,
    createdAt: createdAt ?? DateTime.utc(2026, 8, 18, 12),
  );
}

void main() {
  final peach = _save(id: '1', collectionId: 'recipes');
  final other = _save(
    id: '2',
    title: 'Something else',
    url: 'https://example.com/other',
    status: ContentStatus.pending,
  );

  test('search matches title or url', () {
    final result = SaveQuery.apply(
      saves: [peach, other],
      filter: const SaveFilter(query: 'PEACH'),
    );
    expect(result.map((item) => item.id), ['1']);
  });

  test('unfiled and one collection scopes', () {
    expect(
      SaveQuery.apply(
        saves: [peach, other],
        filter: const SaveFilter(collection: CollectionScope.unfiled()),
      ).map((item) => item.id),
      ['2'],
    );
    expect(
      SaveQuery.apply(
        saves: [peach, other],
        filter: const SaveFilter(collection: CollectionScope.one('recipes')),
      ).map((item) => item.id),
      ['1'],
    );
  });

  test('status filter', () {
    expect(
      SaveQuery.apply(
        saves: [peach, other],
        filter: const SaveFilter(status: ContentStatus.ready),
      ).map((item) => item.id),
      ['1'],
    );
  });

  test('today filter keeps only today', () {
    final now = DateTime(2026, 8, 18, 20);
    final today = _save(id: 'today', createdAt: DateTime(2026, 8, 18, 9));
    final yesterday = _save(id: 'yesterday', createdAt: DateTime(2026, 8, 17, 22));
    final result = SaveQuery.apply(
      saves: [today, yesterday],
      filter: const SaveFilter(when: SaveWhen.today),
      now: now,
    );
    expect(result.map((item) => item.id), ['today']);
  });

  test('category filter matches category name', () {
    final video = _save(id: 'v1').copyWith(category: 'Video');
    final article = _save(id: 'a1').copyWith(category: 'Article');
    final result = SaveQuery.apply(
      saves: [video, article],
      filter: const SaveFilter(category: 'Video'),
    );
    expect(result.map((item) => item.id), ['v1']);
  });

  test('app filter matches tiktok host', () {
    final tiktok = _save(id: 'tt', url: 'https://vm.tiktok.com/ZMabc/');
    final web = _save(id: 'web', url: 'https://example.com/x');
    final result = SaveQuery.apply(
      saves: [tiktok, web],
      filter: const SaveFilter(appId: 'tiktok'),
    );
    expect(result.map((item) => item.id), ['tt']);
  });

  test('groups saves as today, yesterday, then older', () {
    final now = DateTime(2026, 8, 18, 20);
    final groups = SaveTimeline.group(
      [
        _save(id: 't', createdAt: DateTime(2026, 8, 18, 10)),
        _save(id: 'y', createdAt: DateTime(2026, 8, 17, 9)),
        _save(id: 'old', createdAt: DateTime(2026, 8, 1, 9)),
      ],
      now: now,
    );
    expect(groups.map((group) => group.label), ['Today', 'Yesterday', '1 Aug 2026']);
    expect(groups.first.items.single.id, 't');
  });

  test('source app maps known hosts', () {
    expect(SourceApp.idFor('https://www.instagram.com/p/x'), 'instagram');
    expect(SourceApp.label('youtube'), 'YouTube');
  });
}
