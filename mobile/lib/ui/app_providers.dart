import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:later/data/local/app_database.dart';
import 'package:later/data/repositories/auth_repository.dart';
import 'package:later/data/repositories/collection_repository.dart';
import 'package:later/data/repositories/save_repository.dart';
import 'package:later/data/repositories/settings_repository.dart';
import 'package:later/data/services/api_client.dart';
import 'package:later/data/services/incoming_shares.dart';
import 'package:later/domain/models/save.dart';
import 'package:later/domain/models/save_query.dart';
import 'package:later/domain/share_intake.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('override in main');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(sharedPreferencesProvider));
});

final welcomeSeenProvider = StateNotifierProvider<WelcomeSeenController, bool>((ref) {
  return WelcomeSeenController(ref.watch(settingsRepositoryProvider));
});

class WelcomeSeenController extends StateNotifier<bool> {
  WelcomeSeenController(this._settings) : super(_settings.hasSeenWelcome());

  final SettingsRepository _settings;

  Future<void> completeWelcome() async {
    await _settings.setHasSeenWelcome(true);
    state = true;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(settingsRepositoryProvider));
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._settings) : super(_settings.themeMode());

  final SettingsRepository _settings;

  Future<void> setMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    state = mode;
  }
}

final appLanguageProvider = StateNotifierProvider<AppLanguageController, String>((ref) {
  return AppLanguageController(ref.watch(settingsRepositoryProvider));
});

class AppLanguageController extends StateNotifier<String> {
  AppLanguageController(this._settings) : super(_settings.appLanguage());

  final SettingsRepository _settings;

  Future<void> setLanguage(String lang) async {
    await _settings.setAppLanguage(lang);
    state = lang;
  }
}

final aiEnabledProvider = StateNotifierProvider<BoolSettingController, bool>((ref) {
  return BoolSettingController(ref.watch(sharedPreferencesProvider), 'ai_enabled', true);
});

final aiSummarizationProvider = StateNotifierProvider<BoolSettingController, bool>((ref) {
  return BoolSettingController(ref.watch(sharedPreferencesProvider), 'ai_summarization', true);
});

final aiCategorizationProvider = StateNotifierProvider<BoolSettingController, bool>((ref) {
  return BoolSettingController(ref.watch(sharedPreferencesProvider), 'ai_categorization', true);
});

final aiTagsEnabledProvider = StateNotifierProvider<BoolSettingController, bool>((ref) {
  return BoolSettingController(ref.watch(sharedPreferencesProvider), 'ai_tags', true);
});

class BoolSettingController extends StateNotifier<bool> {
  BoolSettingController(this._prefs, this._key, bool defaultValue)
      : super(_prefs.getBool(_key) ?? defaultValue);

  final SharedPreferences _prefs;
  final String _key;

  Future<void> set(bool value) async {
    await _prefs.setBool(_key, value);
    state = value;
  }
}

final apiBaseUrlProvider = StateNotifierProvider<ApiBaseUrlController, String>((ref) {
  return ApiBaseUrlController(ref.watch(settingsRepositoryProvider));
});

class ApiBaseUrlController extends StateNotifier<String> {
  ApiBaseUrlController(this._settings) : super(_settings.apiBaseUrl());

  final SettingsRepository _settings;

  Future<void> setUrl(String url) async {
    await _settings.setApiBaseUrl(url);
    state = _settings.apiBaseUrl();
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authTokenProvider = StateNotifierProvider<AuthTokenController, String?>((ref) {
  return AuthTokenController(ref.watch(secureStorageProvider));
});

class AuthTokenController extends StateNotifier<String?> {
  AuthTokenController(this._storage) : super(null) {
    _storage.read(key: AuthRepository.tokenKey).then((value) => state = value);
  }

  final FlutterSecureStorage _storage;

  void setToken(String? token) => state = token;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    storage: ref.watch(secureStorageProvider),
    baseUrl: ref.watch(apiBaseUrlProvider),
  );
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    token: ref.watch(authTokenProvider),
  );
});

final saveRepositoryProvider = Provider<SaveRepository>((ref) {
  return SaveRepository(
    db: ref.watch(databaseProvider),
    api: ref.watch(apiClientProvider),
  );
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository(
    db: ref.watch(databaseProvider),
    api: ref.watch(apiClientProvider),
  );
});

final savesProvider = StreamProvider((ref) {
  return ref.watch(saveRepositoryProvider).watchAlive();
});

final collectionsProvider = StreamProvider((ref) {
  return ref.watch(collectionRepositoryProvider).watchAlive();
});

final saveFilterProvider = StateNotifierProvider<SaveFilterController, SaveFilter>((ref) {
  return SaveFilterController();
});

class SaveFilterController extends StateNotifier<SaveFilter> {
  SaveFilterController() : super(const SaveFilter());

  void setQuery(String query) => state = state.copyWith(query: query);

  void setCollection(CollectionScope collection) {
    state = state.copyWith(collection: collection);
  }

  void setStatus(ContentStatus? status) {
    state = status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(status: status);
  }

  void setWhen(SaveWhen when) => state = state.copyWith(when: when);

  void setApp(String? appId) {
    state = appId == null ? state.copyWith(clearApp: true) : state.copyWith(appId: appId);
  }

  void setCategory(String? category) {
    state = category == null ? state.copyWith(clearCategory: true) : state.copyWith(category: category);
  }

  void setSort(SaveSort sort) => state = state.copyWith(sort: sort);

  void setPriorityFilter(PriorityFilter priorityFilter) => state = state.copyWith(priorityFilter: priorityFilter);

  void clearAdvanced() => state = state.clearAdvanced();
}

final visibleSavesProvider = Provider<AsyncValue<List<SaveItem>>>((ref) {
  final filter = ref.watch(saveFilterProvider);
  return ref.watch(savesProvider).whenData(
        (items) => SaveQuery.apply(saves: items, filter: filter),
      );
});

final shareIntakeProvider = Provider<ShareIntake>((ref) {
  return ShareIntake(
    saves: ref.watch(saveRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

final incomingSharesProvider = Provider<IncomingShares>((ref) {
  return ShareHandlerIncomingShares();
});

bool _isSyncingLater = false;

Future<void> syncLater(WidgetRef ref) async {
  if (_isSyncingLater) return;
  _isSyncingLater = true;
  try {
    await ref.read(collectionRepositoryProvider).sync();
    await ref.read(saveRepositoryProvider).sync();
  } finally {
    _isSyncingLater = false;
  }
}
