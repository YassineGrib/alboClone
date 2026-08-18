import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/local/app_database.dart';
import 'package:later/data/repositories/save_repository.dart';
import 'package:later/data/services/api_client.dart';
import 'package:later/domain/models/save.dart';

class _DownApi extends ApiClient {
  _DownApi() : super(baseUrl: 'http://127.0.0.1:9');

  @override
  Future<Map<String, dynamic>> createSave({
    required String id,
    required String url,
    required String title,
    required DateTime createdAt,
    String? collectionId,
    bool aiEnabled = true,
  }) async {
    throw ApiException("Couldn't reach the server.");
  }
}

void main() {
  late AppDatabase db;
  late SaveRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SaveRepository(db: db, api: _DownApi());
  });

  tearDown(() async {
    await db.close();
  });

  test('addUrl writes locally when the API is down', () async {
    final item = await repo.addUrl('https://example.com/x');
    expect(item.syncStatus, SyncStatus.syncFailed);
    final rows = await db.select(db.saves).get();
    expect(rows, hasLength(1));
    expect(rows.first.url, 'https://example.com/x');
  });

  test('invalid url writes nothing', () async {
    expect(
      () => repo.addUrl('not-a-url'),
      throwsA(isA<FormatException>()),
    );
    final rows = await db.select(db.saves).get();
    expect(rows, isEmpty);
  });
}
