import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/local/app_database.dart';
import 'package:later/data/repositories/collection_repository.dart';
import 'package:later/data/services/api_client.dart';
import 'package:later/domain/models/save.dart';

class _DownApi extends ApiClient {
  _DownApi() : super(baseUrl: 'http://127.0.0.1:9');

  @override
  Future<Map<String, dynamic>> createCollection({
    required String id,
    required String name,
  }) async {
    throw ApiException("Couldn't reach the server.");
  }
}

void main() {
  late AppDatabase db;
  late CollectionRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CollectionRepository(db: db, api: _DownApi());
  });

  tearDown(() async {
    await db.close();
  });

  test('create writes locally when the API is down', () async {
    final item = await repo.create('Recipes');
    expect(item.syncStatus, SyncStatus.syncFailed);
    final rows = await db.select(db.collections).get();
    expect(rows, hasLength(1));
    expect(rows.first.name, 'Recipes');
  });

  test('blank name writes nothing', () async {
    expect(() => repo.create('  '), throwsA(isA<FormatException>()));
    final rows = await db.select(db.collections).get();
    expect(rows, isEmpty);
  });
}
