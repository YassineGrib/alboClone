import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/local/app_database.dart';
import 'package:later/data/repositories/backup_repository.dart';
import 'package:later/data/repositories/save_repository.dart';
import 'package:later/data/services/api_client.dart';

void main() {
  late AppDatabase db;
  late SaveRepository saveRepository;
  late BackupRepository backupRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final api = ApiClient(baseUrl: 'https://later-dz.site', token: null);
    saveRepository = SaveRepository(db: db, api: api);
    backupRepository = BackupRepository(db: db, saveRepository: saveRepository);
  });

  tearDown(() async {
    await db.close();
  });

  test('BackupRepository restores collections and saves from JSON', () async {
    const jsonSample = '''
{
  "version": "1.0",
  "exported_at": "2026-08-30T12:05:17.254064",
  "collections": [
    {
      "id": "test-col-1",
      "name": "Tech",
      "description": null,
      "is_shared": false
    }
  ],
  "saves": [
    {
      "id": "test-save-1",
      "url": "https://example.com/flutter",
      "title": "Flutter Documentation",
      "ai_summary": "Guide to building apps with Flutter",
      "category": "Article",
      "ai_tags": ["flutter", "dart"],
      "priority": 1,
      "collection_id": "test-col-1",
      "created_at": "2026-08-30T09:44:18.000"
    }
  ]
}
''';

    final restoredCount = await backupRepository.restoreFromJson(jsonSample);
    expect(restoredCount, equals(1));

    final col = await (db.select(db.collections)..where((row) => row.id.equals('test-col-1'))).getSingle();
    expect(col.name, equals('Tech'));

    final save = await (db.select(db.saves)..where((row) => row.id.equals('test-save-1'))).getSingle();
    expect(save.url, equals('https://example.com/flutter'));
    expect(save.title, equals('Flutter Documentation'));
    expect(save.aiSummary, equals('Guide to building apps with Flutter'));
    expect(save.aiTags, equals('flutter,dart'));

    final backupJson = await backupRepository.generateBackupJson();
    expect(backupJson, contains('https://example.com/flutter'));
    expect(backupJson, contains('Tech'));
  });
}
