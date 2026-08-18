import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/local/app_database.dart';
import 'package:later/data/repositories/save_repository.dart';
import 'package:later/data/repositories/settings_repository.dart';
import 'package:later/data/services/api_client.dart';
import 'package:later/domain/share_intake.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late SaveRepository saves;
  late SettingsRepository settings;
  late ShareIntake intake;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    saves = SaveRepository(db: db, api: _DownApi());
    settings = SettingsRepository(await SharedPreferences.getInstance());
    intake = ShareIntake(saves: saves, settings: settings);
  });

  tearDown(() async {
    await db.close();
  });

  test('signed in saves the extracted url locally', () async {
    final result = await intake.handle(
      'Check https://example.com/x',
      signedIn: true,
    );
    expect(result, ShareIntakeResult.saved);
    final rows = await db.select(db.saves).get();
    expect(rows.single.url, 'https://example.com/x');
  });

  test('signed out stashes the url and writes nothing', () async {
    final result = await intake.handle(
      'https://example.com/x',
      signedIn: false,
    );
    expect(result, ShareIntakeResult.queued);
    expect(await db.select(db.saves).get(), isEmpty);
    expect(settings.pendingShareUrl(), 'https://example.com/x');
  });

  test('drain after login saves the stashed url', () async {
    await intake.handle('https://example.com/x', signedIn: false);
    final result = await intake.drainPending();
    expect(result, ShareIntakeResult.saved);
    expect(settings.pendingShareUrl(), isNull);
    final rows = await db.select(db.saves).get();
    expect(rows.single.url, 'https://example.com/x');
  });

  test('no url is ignored', () async {
    expect(
      await intake.handle('nope', signedIn: true),
      ShareIntakeResult.ignored,
    );
    expect(await db.select(db.saves).get(), isEmpty);
  });
}
